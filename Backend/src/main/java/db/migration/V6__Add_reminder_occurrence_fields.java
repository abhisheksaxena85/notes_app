package db.migration;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.Statement;

/**
 * REM-07: repeating reminders keep their first occurrence and the answer to
 * the last handled occurrence.
 *
 * <ul>
 *   <li>{@code start_at VARCHAR(255)}: backfilled with {@code remind_at}, so
 *       existing series are anchored where they are now;</li>
 *   <li>{@code last_outcome VARCHAR(16)} (COMPLETED / MISSED) and
 *       {@code last_outcome_at VARCHAR(255)}: nullable, empty for old rows.</li>
 * </ul>
 *
 * Equivalent manual SQL on MySQL:
 * <pre>
 * ALTER TABLE reminders ADD COLUMN start_at VARCHAR(255) NULL;
 * ALTER TABLE reminders ADD COLUMN last_outcome VARCHAR(16) NULL;
 * ALTER TABLE reminders ADD COLUMN last_outcome_at VARCHAR(255) NULL;
 * UPDATE reminders SET start_at = remind_at WHERE start_at IS NULL;
 * </pre>
 *
 * On a fresh database the table doesn't exist yet and Hibernate creates it
 * with these columns, so the migration does nothing.
 */
public class V6__Add_reminder_occurrence_fields extends BaseJavaMigration {

    @Override
    public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        String table = MigrationSupport.findTable(connection, "reminders");
        if (table == null) {
            return;
        }
        try (Statement statement = connection.createStatement()) {
            if (!MigrationSupport.columnExists(connection, table, "start_at")) {
                statement.execute("ALTER TABLE reminders ADD COLUMN start_at VARCHAR(255) NULL");
            }
            if (!MigrationSupport.columnExists(connection, table, "last_outcome")) {
                statement.execute("ALTER TABLE reminders ADD COLUMN last_outcome VARCHAR(16) NULL");
            }
            if (!MigrationSupport.columnExists(connection, table, "last_outcome_at")) {
                statement.execute("ALTER TABLE reminders ADD COLUMN last_outcome_at VARCHAR(255) NULL");
            }
            if (MigrationSupport.columnExists(connection, table, "remind_at")) {
                statement.executeUpdate("UPDATE reminders SET start_at = remind_at WHERE start_at IS NULL");
            }
        }
    }
}
