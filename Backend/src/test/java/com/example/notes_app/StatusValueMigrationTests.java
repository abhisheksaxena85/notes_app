package com.example.notes_app;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

/**
 * BE-04: Flyway V5 rewrites stored status/priority/repeat values to the enum
 * names, so loading a list can't fail on an old free-text value.
 */
public class StatusValueMigrationTests {

    @Test
    public void normalisesStoredValues() throws Exception {
        String url = "jdbc:h2:mem:status_values_" + UUID.randomUUID().toString().replace("-", "")
                + ";MODE=MySQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE";
        try (Connection connection = DriverManager.getConnection(url, "sa", "")) {
            try (Statement statement = connection.createStatement()) {
                statement.execute("CREATE TABLE tasks (task_id BIGINT AUTO_INCREMENT PRIMARY KEY,"
                        + " title VARCHAR(255) NOT NULL, status VARCHAR(255), priority VARCHAR(255),"
                        + " user_id BIGINT NOT NULL)");
                statement.execute("CREATE TABLE reminders (reminder_id BIGINT AUTO_INCREMENT PRIMARY KEY,"
                        + " title VARCHAR(255) NOT NULL, status VARCHAR(255), repeat_interval VARCHAR(255),"
                        + " user_id BIGINT NOT NULL)");
                statement.execute("INSERT INTO tasks (title, status, priority, user_id) VALUES"
                        + " ('a', 'completed', ' high ', 1), ('b', 'foo', NULL, 1), ('c', NULL, 'urgent', 1)");
                statement.execute("INSERT INTO reminders (title, status, repeat_interval, user_id) VALUES"
                        + " ('a', 'Missed', 'daily', 1), ('b', 'FOO', NULL, 1), ('c', 'PENDING', 'hourly', 1)");
            }

            var result = Flyway.configure()
                    .dataSource(url, "sa", "")
                    .locations("classpath:db/migration")
                    .baselineOnMigrate(true)
                    .baselineVersion("1")
                    .target("5")
                    .load()
                    .migrate();
            assertTrue(result.success);

            assertEquals(List.of("COMPLETED/HIGH", "PENDING/MEDIUM", "PENDING/MEDIUM"),
                    rows(connection, "SELECT status, priority FROM tasks ORDER BY task_id"));
            assertEquals(List.of("MISSED/DAILY", "PENDING/NONE", "PENDING/NONE"),
                    rows(connection, "SELECT status, repeat_interval FROM reminders ORDER BY reminder_id"));
        }
    }

    private static List<String> rows(Connection connection, String sql) throws Exception {
        List<String> values = new ArrayList<>();
        try (Statement statement = connection.createStatement(); ResultSet rs = statement.executeQuery(sql)) {
            while (rs.next()) {
                values.add(rs.getString(1) + "/" + rs.getString(2));
            }
        }
        return values;
    }
}
