package db.migration;

import org.flywaydb.core.api.migration.BaseJavaMigration;
import org.flywaydb.core.api.migration.Context;

import java.sql.Connection;
import java.sql.Statement;

/**
 * BE-01: notes longer than 255 characters failed to save because Hibernate had
 * created {@code notes.title} and {@code notes.content} as VARCHAR(255), and
 * {@code ddl-auto=update} never widens an existing column.
 *
 * <ul>
 *   <li>{@code content} becomes LONGTEXT.</li>
 *   <li>{@code title} becomes VARCHAR(500).</li>
 * </ul>
 *
 * Both changes only widen the columns, so no data can be lost. Equivalent manual
 * SQL on MySQL:
 * <pre>
 * ALTER TABLE notes MODIFY content LONGTEXT NULL;
 * ALTER TABLE notes MODIFY title VARCHAR(500) NULL;
 * </pre>
 *
 * On a brand-new database the {@code notes} table does not exist yet (Hibernate
 * creates it after Flyway, already with these types), so the migration does nothing.
 */
public class V3__Widen_note_columns extends BaseJavaMigration {

    static final int TITLE_LENGTH = 500;

    @Override
    public void migrate(Context context) throws Exception {
        Connection connection = context.getConnection();
        if (MigrationSupport.findTable(connection, "notes") == null) {
            return;
        }

        try (Statement statement = connection.createStatement()) {
            if (MigrationSupport.isMySql(connection)) {
                statement.execute("ALTER TABLE notes MODIFY content LONGTEXT NULL");
                statement.execute("ALTER TABLE notes MODIFY title VARCHAR(" + TITLE_LENGTH + ") NULL");
            } else {
                statement.execute("ALTER TABLE notes ALTER COLUMN content SET DATA TYPE LONGTEXT");
                statement.execute("ALTER TABLE notes ALTER COLUMN title SET DATA TYPE VARCHAR(" + TITLE_LENGTH + ")");
            }
        }
    }
}
