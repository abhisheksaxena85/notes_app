package com.example.notes_app;

import org.flywaydb.core.Flyway;
import org.flywaydb.core.api.FlywayException;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

/**
 * SEC-05: runs the real Flyway migrations (baseline at 1, then V2) against a
 * throw-away H2 database in MySQL mode that looks like the existing production
 * schema (email stored as TEXT, no unique index).
 */
public class EmailMigrationTests {

    private static String newDatabaseUrl() {
        return "jdbc:h2:mem:migration_" + UUID.randomUUID().toString().replace("-", "")
                + ";MODE=MySQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE";
    }

    private static Flyway flyway(String url) {
        return Flyway.configure()
                .dataSource(url, "sa", "")
                .locations("classpath:db/migration")
                .baselineOnMigrate(true)
                .baselineVersion("1")
                .load();
    }

    private static void createLegacyUsersTable(Connection connection, String... emails) throws SQLException {
        try (Statement statement = connection.createStatement()) {
            statement.execute("CREATE TABLE users (id BIGINT AUTO_INCREMENT PRIMARY KEY, name TEXT, email TEXT, password TEXT)");
            for (String email : emails) {
                statement.execute("INSERT INTO users (name, email, password) VALUES ('n', "
                        + (email == null ? "NULL" : "'" + email + "'") + ", 'hash')");
            }
        }
    }

    private static List<String> emails(Connection connection) throws SQLException {
        List<String> result = new ArrayList<>();
        try (Statement statement = connection.createStatement();
             ResultSet rs = statement.executeQuery("SELECT email FROM users ORDER BY id")) {
            while (rs.next()) {
                result.add(rs.getString(1));
            }
        }
        return result;
    }

    @Test
    public void lowercasesEmailsAndAddsUniqueIndex() throws Exception {
        String url = newDatabaseUrl();
        try (Connection connection = DriverManager.getConnection(url, "sa", "")) {
            createLegacyUsersTable(connection, " Alice@Example.COM ", "bob@example.com", null, null);

            flyway(url).migrate();

            assertEquals(List.of("alice@example.com", "bob@example.com"), emails(connection).subList(0, 2));
            assertNull(emails(connection).get(2), "NULL emails are left alone");
            assertEquals(4, emails(connection).size(), "no rows are removed");

            try (ResultSet rs = connection.getMetaData().getColumns(null, null, "users", "email")) {
                assertTrue(rs.next());
                assertEquals(320, rs.getInt("COLUMN_SIZE"));
            }
            try (Statement statement = connection.createStatement()) {
                assertThrows(SQLException.class, () -> statement.execute(
                        "INSERT INTO users (name, email, password) VALUES ('n', 'bob@example.com', 'h')"));
            }
        }
    }

    @Test
    public void duplicatesStopTheMigrationWithoutChangingData() throws Exception {
        String url = newDatabaseUrl();
        try (Connection connection = DriverManager.getConnection(url, "sa", "")) {
            createLegacyUsersTable(connection, "Carol@x.com", "carol@x.com ", "dave@x.com");

            FlywayException error = assertThrows(FlywayException.class, () -> flyway(url).migrate());

            // Flyway wraps the migration's exception; the startup log prints the whole chain.
            StringBuilder chain = new StringBuilder();
            for (Throwable t = error; t != null; t = t.getCause()) {
                chain.append(t.getMessage()).append('\n');
            }
            String message = chain.toString();
            assertTrue(message.contains("used by more than one account"), message);
            assertTrue(message.contains("[[1, 2]]"), message);
            assertTrue(message.contains("No data was deleted"), message);
            assertFalse(message.contains("carol@x.com"), "emails are not written to logs");

            assertEquals(List.of("Carol@x.com", "carol@x.com ", "dave@x.com"), emails(connection),
                    "rows are kept and the lower-casing is rolled back");
        }
    }

    @Test
    public void freshDatabaseWithoutUsersTableIsANoOp() {
        String url = newDatabaseUrl();
        var result = flyway(url).migrate();
        assertTrue(result.success);
        assertEquals("3", result.targetSchemaVersion);
    }
}
