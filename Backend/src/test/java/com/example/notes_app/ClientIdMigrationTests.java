package com.example.notes_app;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

/**
 * FE-03: Flyway V4 adds notes/tasks/reminders.client_id and a unique
 * (user_id, client_id) index on a database created before it, keeping rows.
 */
public class ClientIdMigrationTests {

    private static Flyway flyway(String url) {
        return Flyway.configure()
                .dataSource(url, "sa", "")
                .locations("classpath:db/migration")
                .baselineOnMigrate(true)
                .baselineVersion("1")
                .load();
    }

    @Test
    public void addsClientIdColumnsAndUniqueIndexes() throws Exception {
        String url = "jdbc:h2:mem:client_id_" + UUID.randomUUID().toString().replace("-", "")
                + ";MODE=MySQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE";
        try (Connection connection = DriverManager.getConnection(url, "sa", "")) {
            try (Statement statement = connection.createStatement()) {
                statement.execute("CREATE TABLE notes (note_id BIGINT AUTO_INCREMENT PRIMARY KEY,"
                        + " title VARCHAR(255), content VARCHAR(255), user_id BIGINT NOT NULL)");
                statement.execute("CREATE TABLE tasks (task_id BIGINT AUTO_INCREMENT PRIMARY KEY,"
                        + " title VARCHAR(255) NOT NULL, user_id BIGINT NOT NULL)");
                statement.execute("CREATE TABLE reminders (reminder_id BIGINT AUTO_INCREMENT PRIMARY KEY,"
                        + " title VARCHAR(255) NOT NULL, user_id BIGINT NOT NULL)");
                statement.execute("INSERT INTO notes (title, content, user_id) VALUES ('old', 'x', 1)");
                statement.execute("INSERT INTO tasks (title, user_id) VALUES ('old', 1)");
            }

            var result = flyway(url).migrate();
            assertEquals("4", result.targetSchemaVersion);

            try (Statement statement = connection.createStatement()) {
                for (String table : new String[]{"notes", "tasks", "reminders"}) {
                    // Old rows and old clients: NULL client ids never clash.
                    statement.execute("INSERT INTO " + table + " (title, user_id) VALUES ('a', 1)");
                    statement.execute("INSERT INTO " + table + " (title, user_id) VALUES ('b', 1)");
                    statement.execute("INSERT INTO " + table + " (title, user_id, client_id) VALUES ('c', 1, 'id-1')");
                    statement.execute("INSERT INTO " + table + " (title, user_id, client_id) VALUES ('d', 2, 'id-1')");
                    assertThrows(SQLException.class, () -> statement.execute(
                            "INSERT INTO " + table + " (title, user_id, client_id) VALUES ('e', 1, 'id-1')"),
                            table + " rejects a duplicate client id for the same user");
                }
                try (ResultSet rs = statement.executeQuery("SELECT COUNT(*) FROM notes WHERE title = 'old'")) {
                    assertTrue(rs.next());
                    assertEquals(1, rs.getInt(1), "existing rows are kept");
                }
            }
        }
    }
}
