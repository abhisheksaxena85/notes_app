package db.migration;

import org.flywaydb.core.api.FlywayException;
import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * SEC-05: one account per email, regardless of case or surrounding spaces.
 *
 * <ol>
 *   <li>Lower-case and trim every stored email.</li>
 *   <li>If two accounts now share an email (or an email is longer than 320
 *       characters), stop with a clear error. Nothing is deleted or merged: the
 *       update in step 1 runs in the same transaction and is rolled back.</li>
 *   <li>Change {@code users.email} from TEXT to VARCHAR(320) and add the unique
 *       index {@code uk_users_email}.</li>
 * </ol>
 *
 * Written in Java rather than SQL because MySQL can only raise a custom error
 * from a stored procedure, and creating one is DDL that would commit step 1
 * before the duplicate check.
 *
 * On a brand-new database the {@code users} table does not exist yet (Hibernate
 * creates it after Flyway runs, already with the right column and index), so
 * the migration does nothing.
 */
public class V2__Normalise_user_emails extends BaseJavaMigration {

    static final int MAX_EMAIL_LENGTH = 320;
    static final String INDEX_NAME = "uk_users_email";

    @Override
    public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        String table = findTable(connection, "users");
        if (table == null) {
            return;
        }

        try (Statement statement = connection.createStatement()) {
            statement.executeUpdate("UPDATE users SET email = LOWER(TRIM(email)) WHERE email IS NOT NULL");
        }

        List<String> problems = new ArrayList<>();
        List<List<Long>> duplicateGroups = findDuplicateGroups(connection);
        if (!duplicateGroups.isEmpty()) {
            problems.add(duplicateGroups.size() + " email address(es) are used by more than one account"
                    + " once lower-cased; user ids sharing an email: " + duplicateGroups);
        }
        List<Long> tooLong = findIds(connection,
                "SELECT id FROM users WHERE CHAR_LENGTH(email) > " + MAX_EMAIL_LENGTH + " ORDER BY id");
        if (!tooLong.isEmpty()) {
            problems.add("emails longer than " + MAX_EMAIL_LENGTH + " characters for user ids " + tooLong);
        }
        if (!problems.isEmpty()) {
            throw new FlywayException("V2 (unique user emails) cannot be applied: " + String.join("; ", problems)
                    + ". No data was deleted and the lower-casing was rolled back. Resolve these accounts by hand"
                    + " (for example change one email in each group), then remove the failed version 2 row from"
                    + " flyway_schema_history (or run 'flyway repair') and restart the backend.");
        }

        try (Statement statement = connection.createStatement()) {
            if (isMySql(connection)) {
                statement.execute("ALTER TABLE users MODIFY email VARCHAR(" + MAX_EMAIL_LENGTH + ") NULL");
            } else {
                statement.execute("ALTER TABLE users ALTER COLUMN email SET DATA TYPE VARCHAR(" + MAX_EMAIL_LENGTH + ")");
            }
            if (!indexExists(connection, table, INDEX_NAME)) {
                statement.execute("CREATE UNIQUE INDEX " + INDEX_NAME + " ON users (email)");
            }
        }
    }

    /** Ids of accounts that share an email, one list per email (emails are not logged). */
    private static List<List<Long>> findDuplicateGroups(Connection connection) throws SQLException {
        List<String> emails = new ArrayList<>();
        try (Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery(
                     "SELECT email FROM users WHERE email IS NOT NULL GROUP BY email HAVING COUNT(*) > 1")) {
            while (rs.next()) {
                emails.add(rs.getString(1));
            }
        }
        List<List<Long>> groups = new ArrayList<>();
        try (PreparedStatement statement = connection.prepareStatement(
                "SELECT id FROM users WHERE email = ? ORDER BY id")) {
            for (String email : emails) {
                statement.setString(1, email);
                List<Long> ids = new ArrayList<>();
                try (ResultSet rs = statement.executeQuery()) {
                    while (rs.next()) {
                        ids.add(rs.getLong(1));
                    }
                }
                groups.add(ids);
            }
        }
        return groups;
    }

    private static List<Long> findIds(Connection connection, String sql) throws SQLException {
        List<Long> ids = new ArrayList<>();
        try (Statement statement = connection.createStatement(); ResultSet rs = statement.executeQuery(sql)) {
            while (rs.next()) {
                ids.add(rs.getLong(1));
            }
        }
        return ids;
    }

    /**
     * The table name as the database reports it, or null if it does not exist.
     * Only the current catalog/schema is searched (MySQL uses the catalog, H2 the
     * schema), so system tables such as information_schema.users never match.
     */
    private static String findTable(Connection connection, String name) throws SQLException {
        DatabaseMetaData metaData = connection.getMetaData();
        for (String candidate : new String[]{name, name.toUpperCase()}) {
            try (ResultSet rs = metaData.getTables(
                    connection.getCatalog(), connection.getSchema(), candidate, new String[]{"TABLE"})) {
                if (rs.next()) {
                    return rs.getString("TABLE_NAME");
                }
            }
        }
        return null;
    }

    private static boolean indexExists(Connection connection, String table, String indexName) throws SQLException {
        try (ResultSet rs = connection.getMetaData().getIndexInfo(
                connection.getCatalog(), connection.getSchema(), table, false, false)) {
            while (rs.next()) {
                if (indexName.equalsIgnoreCase(rs.getString("INDEX_NAME"))) {
                    return true;
                }
            }
        }
        return false;
    }

    private static boolean isMySql(Connection connection) throws SQLException {
        String product = connection.getMetaData().getDatabaseProductName().toLowerCase();
        return product.contains("mysql") || product.contains("mariadb");
    }
}
