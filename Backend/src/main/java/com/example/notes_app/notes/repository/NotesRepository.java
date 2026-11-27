package com.example.notes_app.notes.repository;

import com.example.notes_app.notes.model.NotesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface NotesRepository extends JpaRepository<NotesModel, Long> {
    List<NotesModel> findByUser_IdOrderByIsPinnedDescCreatedAtDesc(long userId);

    Optional<NotesModel> findByUser_IdAndClientId(long userId, String clientId);

    /** SEC-01: a note only if it belongs to {@code userId}. */
    Optional<NotesModel> findByNoteIdAndUser_Id(long noteId, long userId);

    @Query("SELECT n FROM NotesModel n WHERE n.user.id = :userId AND (" +
           "LOWER(n.title) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(n.content) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(n.category) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
           "LOWER(n.tags) LIKE LOWER(CONCAT('%', :query, '%')))")
    List<NotesModel> searchNotes(@Param("userId") long userId, @Param("query") String query);
}
