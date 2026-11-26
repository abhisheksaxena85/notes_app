package com.example.notes_app;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

/** REM-07: Flyway V6 adds the occurrence columns and anchors existing reminders at remind_at. */
public class ReminderOccurrenceMigrationTests {

    @Test
    public void addsColumnsAndBackfillsStartAt() throws Exception {
        String url = "jdbc:h2:mem:occurrence_" + UUID.randomUUID().toString().replace("-", "")
                + ";MODE=MySQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE";
        try (Connection connection = DriverManager.getConnection(url, "sa", "")) {
            try (Statement statement = connection.createStatement()) {
                statement.execute("CREATE TABLE reminders (reminder_id BIGINT AUTO_INCREMENT PRIMARY KEY,"
                        + " title VARCHAR(255) NOT NULL, remind_at VARCHAR(255) NOT NULL, status VARCHAR(255),"
                        + " repeat_interval VARCHAR(255), user_id BIGINT NOT NULL)");
                statement.execute("INSERT INTO reminders (title, remind_at, status, repeat_interval, user_id)"
                        + " VALUES ('old', '2026-01-31T09:00:00', 'PENDING', 'MONTHLY', 1)");
            }

            var result = Flyway.configure()
                    .dataSource(url, "sa", "")
                    .locations("classpath:db/migration")
                    .baselineOnMigrate(true)
                    .baselineVersion("1")
                    .load()
                    .migrate();
            assertEquals("6", result.targetSchemaVersion);

            try (Statement statement = connection.createStatement();
                 ResultSet rs = statement.executeQuery(
                         "SELECT start_at, last_outcome, last_outcome_at FROM reminders")) {
                assertTrue(rs.next());
                assertEquals("2026-01-31T09:00:00", rs.getString(1));
                assertNull(rs.getString(2));
                assertNull(rs.getString(3));
            }
        }
    }
}
