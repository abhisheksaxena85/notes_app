package db.migration;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Helpers shared by the Java migrations. Not a migration itself (it does not
 * implement JavaMigration), so Flyway ignores it.
 *
 * Migrations run before Hibernate's ddl-auto, so on a brand-new database the
 * feature tables do not exist yet; each migration checks with {@link #findTable}
 * and does nothing in that case (Hibernate then creates the tables already in
 * their final shape).
 */
final class MigrationSupport {

    private MigrationSupport() {
    }

    /**
     * The table name as the database reports it, or null if it does not exist.
     * Only the current catalog/schema is searched (MySQL uses the catalog, H2 the
     * schema), so system tables never match.
     */
    static String findTable(Connection connection, String name) throws SQLException {
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

    static boolean columnExists(Connection connection, String table, String column) throws SQLException {
        DatabaseMetaData metaData = connection.getMetaData();
        for (String candidate : new String[]{column, column.toUpperCase()}) {
            try (ResultSet rs = metaData.getColumns(
                    connection.getCatalog(), connection.getSchema(), table, candidate)) {
                if (rs.next()) {
                    return true;
                }
            }
        }
        return false;
    }

    static boolean indexExists(Connection connection, String table, String indexName) throws SQLException {
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

    static boolean isMySql(Connection connection) throws SQLException {
        String product = connection.getMetaData().getDatabaseProductName().toLowerCase();
        return product.contains("mysql") || product.contains("mariadb");
    }
}
