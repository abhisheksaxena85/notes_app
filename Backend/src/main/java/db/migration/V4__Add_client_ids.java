package db.migration;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.Statement;

/**
 * FE-03: idempotent creates. Adds a nullable {@code client_id VARCHAR(36)} to
 * notes, tasks and reminders, plus a unique index on (user_id, client_id).
 *
 * Existing rows and old app builds have no client id: the column stays NULL,
 * and NULLs never clash in a MySQL (or H2) unique index, so they keep working.
 *
 * The index names must match the {@code @UniqueConstraint} names on the
 * entities so Hibernate's ddl-auto=update sees them and doesn't add another.
 * Equivalent manual SQL on MySQL, per table:
 * <pre>
 * ALTER TABLE notes ADD COLUMN client_id VARCHAR(36) NULL;
 * CREATE UNIQUE INDEX uk_notes_user_client ON notes (user_id, client_id);
 * </pre>
 *
 * Tables that do not exist yet (fresh database) are skipped; Hibernate creates
 * them afterwards with the column and the index.
 */
public class V4__Add_client_ids extends BaseJavaMigration {

    static final String[] TABLES = {"notes", "tasks", "reminders"};

    static String indexName(String table) {
        return "uk_" + table + "_user_client";
    }

    @Override
    public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        for (String name : TABLES) {
            String table = MigrationSupport.findTable(connection, name);
            if (table == null) {
                continue;
            }
            try (Statement statement = connection.createStatement()) {
                if (!MigrationSupport.columnExists(connection, table, "client_id")) {
                    statement.execute("ALTER TABLE " + name + " ADD COLUMN client_id VARCHAR(36) NULL");
                }
                if (!MigrationSupport.indexExists(connection, table, indexName(name))) {
                    statement.execute("CREATE UNIQUE INDEX " + indexName(name)
                            + " ON " + name + " (user_id, client_id)");
                }
            }
        }
    }
}
