package db.migration;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.Statement;

/**
 * BE-04: {@code status}, {@code priority} and {@code repeat_interval} are now
 * Java enums. Before, any string could be stored (for example
 * {@code update-status?status=foo}), and one unknown value would make loading
 * that user's list fail. This rewrites stored values to the enum names:
 *
 * <ul>
 *   <li>upper-case and trim every value;</li>
 *   <li>unknown or missing values become the defaults the API already used
 *       ({@code PENDING}, {@code MEDIUM}, {@code NONE}).</li>
 * </ul>
 *
 * Equivalent manual SQL on MySQL:
 * <pre>
 * UPDATE reminders SET status = UPPER(TRIM(status)) WHERE status IS NOT NULL;
 * UPDATE reminders SET status = 'PENDING'
 *   WHERE status IS NULL OR status NOT IN ('PENDING','COMPLETED','REJECTED','MISSED');
 * -- same for tasks.status; tasks.priority (default MEDIUM); reminders.repeat_interval (default NONE)
 * </pre>
 *
 * Tables that do not exist yet (fresh database) are skipped.
 */
public class V5__Normalise_status_values extends BaseJavaMigration {

    static final String STATUSES = "'PENDING','COMPLETED','REJECTED','MISSED'";

    @Override
    public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        if (MigrationSupport.findTable(connection, "tasks") != null) {
            normalise(connection, "tasks", "status", STATUSES, "PENDING");
            normalise(connection, "tasks", "priority", "'LOW','MEDIUM','HIGH'", "MEDIUM");
        }
        if (MigrationSupport.findTable(connection, "reminders") != null) {
            normalise(connection, "reminders", "status", STATUSES, "PENDING");
            normalise(connection, "reminders", "repeat_interval", "'NONE','DAILY','WEEKLY','MONTHLY'", "NONE");
        }
    }

    private static void normalise(Connection connection, String table, String column, String allowed,
                                  String fallback) throws Exception {
        String actual = MigrationSupport.findTable(connection, table);
        if (!MigrationSupport.columnExists(connection, actual, column)) {
            return;
        }
        try (Statement statement = connection.createStatement()) {
            statement.executeUpdate("UPDATE " + table + " SET " + column + " = UPPER(TRIM(" + column + "))"
                    + " WHERE " + column + " IS NOT NULL");
            statement.executeUpdate("UPDATE " + table + " SET " + column + " = '" + fallback + "'"
                    + " WHERE " + column + " IS NULL OR " + column + " NOT IN (" + allowed + ")");
        }
    }
}
