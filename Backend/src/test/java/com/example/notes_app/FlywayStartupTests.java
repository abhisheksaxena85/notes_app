package com.example.notes_app;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

import static org.junit.jupiter.api.Assertions.assertEquals;

/**
 * SEC-05: the app starts with Flyway enabled the way prod runs it (baseline
 * settings from application.properties, ddl-auto=update), on a fresh database.
 */
@SpringBootTest(properties = {
        "spring.flyway.enabled=true",
        "spring.datasource.url=jdbc:h2:mem:flyway_startup;MODE=MySQL;DB_CLOSE_DELAY=-1;DATABASE_TO_LOWER=TRUE",
        "spring.jpa.hibernate.ddl-auto=update",
})
public class FlywayStartupTests {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    public void flywayRunsAndHibernateKeepsTheEmailIndex() {
        String version = jdbcTemplate.queryForObject(
                "SELECT \"version\" FROM \"flyway_schema_history\" WHERE \"success\" = TRUE ORDER BY \"installed_rank\" DESC LIMIT 1",
                String.class);
        assertEquals("2", version);

        // Fresh database: V2 is a no-op and Hibernate creates the table with the named unique key.
        Integer emailConstraints = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM information_schema.table_constraints WHERE LOWER(table_name) = 'users'"
                        + " AND LOWER(constraint_name) = 'uk_users_email' AND constraint_type = 'UNIQUE'",
                Integer.class);
        assertEquals(1, emailConstraints);
    }
}
