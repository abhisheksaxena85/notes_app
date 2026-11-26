package com.example.notes_app.common;

import com.example.notes_app.common.exception.ApiException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.TypeMismatchException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Turns every failure into an {@link ApiResponse} with a matching HTTP status.
 * Messages sent to the client are always fixed, user-safe text; the real
 * exception (SQL, driver errors, stack traces) is only logged server-side.
 */
@RestControllerAdvice
public class GlobalExceptionHandler extends ResponseEntityExceptionHandler {

    static final String GENERIC_ERROR = "Something went wrong";
    static final String CONFLICT_ERROR = "The request conflicts with existing data";
    static final String VALIDATION_ERROR = "Validation failed";

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    /** Expected failures thrown by services (404, 400, 401, 409). */
    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ApiResponse<Void>> handleApiException(ApiException ex) {
        return ResponseEntity.status(ex.getStatus())
                .body(new ApiResponse<>(false, ex.getMessage(), null));
    }

    /** Unique-key or foreign-key violations, e.g. a concurrent duplicate signup. */
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<ApiResponse<Void>> handleDataIntegrity(DataIntegrityViolationException ex) {
        log.warn("Data integrity violation: {}", ex.getMostSpecificCause().getMessage());
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(new ApiResponse<>(false, CONFLICT_ERROR, null));
    }

    /** Anything unexpected: log it, never expose it. */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleUnexpected(Exception ex) {
        log.error("Unhandled exception", ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(new ApiResponse<>(false, GENERIC_ERROR, null));
    }

    /** {@code @Valid @RequestBody} failures: 400 with a field → message map. */
    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(
            MethodArgumentNotValidException ex, HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        Map<String, String> fieldErrors = new LinkedHashMap<>();
        for (FieldError error : ex.getBindingResult().getFieldErrors()) {
            fieldErrors.putIfAbsent(error.getField(), error.getDefaultMessage());
        }
        return validationResponse(fieldErrors, headers);
    }

    /** {@code @RequestParam} constraint failures: 400 with a parameter → message map. */
    @Override
    protected ResponseEntity<Object> handleHandlerMethodValidationException(
            HandlerMethodValidationException ex, HttpHeaders headers, HttpStatusCode status, WebRequest request) {
        Map<String, String> fieldErrors = new LinkedHashMap<>();
        ex.getParameterValidationResults().forEach(result -> {
            String name = result.getMethodParameter().getParameterName();
            result.getResolvableErrors().forEach(error ->
                    fieldErrors.putIfAbsent(name != null ? name : "parameter", error.getDefaultMessage()));
        });
        return validationResponse(fieldErrors, headers);
    }

    /**
     * Every other Spring MVC exception (missing parameter, unreadable body, type
     * mismatch, unsupported method, unknown route, ...) keeps the status Spring
     * picked but gets an ApiResponse body with a safe message.
     */
    @Override
    protected ResponseEntity<Object> handleExceptionInternal(
            Exception ex, Object body, HttpHeaders headers, HttpStatusCode statusCode, WebRequest request) {
        if (statusCode.is5xxServerError()) {
            log.error("Request failed with {}", statusCode, ex);
        }
        return ResponseEntity.status(statusCode)
                .headers(headers)
                .body(new ApiResponse<>(false, messageFor(ex, statusCode), null));
    }

    private ResponseEntity<Object> validationResponse(Map<String, String> fieldErrors, HttpHeaders headers) {
        String message = fieldErrors.values().stream().findFirst().orElse(VALIDATION_ERROR);
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .headers(headers)
                .body(new ApiResponse<>(false, message, fieldErrors));
    }

    private static String messageFor(Exception ex, HttpStatusCode statusCode) {
        if (ex instanceof MissingServletRequestParameterException missing) {
            return "Missing required parameter '" + missing.getParameterName() + "'";
        }
        if (ex instanceof HttpMessageNotReadableException) {
            return "Malformed or missing request body";
        }
        if (ex instanceof TypeMismatchException mismatch && mismatch.getPropertyName() != null) {
            return "Invalid value for '" + mismatch.getPropertyName() + "'";
        }
        if (statusCode.is5xxServerError()) {
            return GENERIC_ERROR;
        }
        HttpStatus resolved = HttpStatus.resolve(statusCode.value());
        return resolved != null ? resolved.getReasonPhrase() : "Request failed";
    }
}
