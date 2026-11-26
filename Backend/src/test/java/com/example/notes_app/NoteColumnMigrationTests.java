package com.example.notes_app;

import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

/**
 * BE-01: Flyway V3 widens notes.title / notes.content on a database created by
 * the old entity (both VARCHAR(255)), keeping existing rows.
 */
public class NoteColumnMigrationTests {

    private static String newDatabaseUrl() {
        return "jdbc:h2:mem:notes_migration_" + UUID.randomUUID().toString().replace("-", "")
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

    @Test
    public void widensLegacyNoteColumnsAndKeepsRows() throws Exception {
        String url = newDatabaseUrl();
        try (Connection connection = DriverManager.getConnection(url, "sa", "")) {
            try (Statement statement = connection.createStatement()) {
                statement.execute("CREATE TABLE notes (note_id BIGINT AUTO_INCREMENT PRIMARY KEY,"
                        + " title VARCHAR(255), content VARCHAR(255), user_id BIGINT NOT NULL)");
                statement.execute("INSERT INTO notes (title, content, user_id) VALUES ('old', 'short body', 1)");
                assertThrows(SQLException.class, () -> statement.execute(
                        "INSERT INTO notes (title, content, user_id) VALUES ('x', '" + "a".repeat(256) + "', 1)"),
                        "precondition: the legacy column rejects long content");
            }

            flyway(url).migrate();

            try (PreparedStatement insert = connection.prepareStatement(
                    "INSERT INTO notes (title, content, user_id) VALUES (?, ?, 1)")) {
                insert.setString(1, "t".repeat(500));
                insert.setString(2, "c".repeat(10_000));
                insert.executeUpdate();
            }
            try (Statement statement = connection.createStatement();
                 ResultSet rs = statement.executeQuery(
                         "SELECT title, CHAR_LENGTH(content) FROM notes ORDER BY note_id")) {
                assertTrue(rs.next());
                assertEquals("old", rs.getString(1), "existing rows are kept");
                assertTrue(rs.next());
                assertEquals(10_000, rs.getInt(2));
            }
            try (ResultSet rs = connection.getMetaData().getColumns(null, null, "notes", "title")) {
                assertTrue(rs.next());
                assertEquals(500, rs.getInt("COLUMN_SIZE"));
            }
        }
    }
}
