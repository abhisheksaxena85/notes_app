/*
 * Daymark account deletion.
 *
 * One flow: sign in (POST /auth/login) -> confirm in a warning dialog ->
 * DELETE /auth/delete-user with the token from sign-in. The server deletes the
 * user together with all of their notes, tasks and reminders.
 *
 * The token lives only in memory for the few seconds the dialog is open. It is
 * never written to storage and is dropped on cancel.
 */
(function () {
  'use strict';

  // Production API. Keep in step with connect-src in index.html's CSP. This
  // page's origin (https://<user>.github.io) must be in the backend's
  // CORS_ALLOWED_ORIGINS.
  var API_BASE_URL = 'https://notesapp-production-d43adec7.up.railway.app';
  // Generous: the server may be waking from a cold start.
  var REQUEST_TIMEOUT_MS = 30000;
  var EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  var MESSAGES = {
    network: "Couldn't reach Daymark. Check your connection and try again.",
    timeout: 'The server took too long to respond. Please try again.',
    server: 'Something went wrong on our side. Please try again in a few minutes.',
    badCredentials: 'Email or password is incorrect.',
    tooManyAttempts: 'Too many failed attempts. Please wait 15 minutes and try again.',
    sessionExpired: 'Your sign-in has expired. Please sign in again.',
    alreadyDeleted: 'This account no longer exists. It may already have been deleted.'
  };

  var $ = function (id) { return document.getElementById(id); };
  var formView = $('form-view');
  var doneView = $('done-view');
  var footer = document.querySelector('.footer');
  var loginForm = $('login-form');
  var emailInput = $('email');
  var passwordInput = $('password');
  var togglePassword = $('toggle-password');
  var continueButton = $('continue-button');
  var formAlert = $('form-alert');
  var dialog = $('confirm-dialog');
  var confirmEmail = $('confirm-email');
  var confirmCheck = $('confirm-check');
  var confirmAlert = $('confirm-alert');
  var cancelButton = $('cancel-button');
  var deleteButton = $('delete-button');

  /** { token, email } between a successful sign-in and delete/cancel. */
  var session = null;
  var busy = false;

  function ApiError(status, message) {
    this.status = status;
    this.message = message;
  }

  /** Calls the API; resolves with `data` of a successful ApiResponse, else rejects with ApiError. */
  function request(path, options) {
    var controller = typeof AbortController === 'function' ? new AbortController() : null;
    var timer = controller ? setTimeout(function () { controller.abort(); }, REQUEST_TIMEOUT_MS) : null;
    var headers = { Accept: 'application/json' };
    if (options.body !== undefined) headers['Content-Type'] = 'application/json';
    if (options.token) headers.Authorization = 'Bearer ' + options.token;

    return fetch(API_BASE_URL + path, {
      method: options.method,
      headers: headers,
      body: options.body === undefined ? undefined : JSON.stringify(options.body),
      signal: controller ? controller.signal : undefined,
      cache: 'no-store',
      credentials: 'omit',
      referrerPolicy: 'no-referrer'
    }).then(function (response) {
      return response.json().catch(function () { return null; }).then(function (payload) {
        if (!response.ok || !payload || payload.success !== true) {
          var message = payload && typeof payload.message === 'string' ? payload.message : null;
          throw new ApiError(response.status, message);
        }
        return payload.data;
      });
    }, function (error) {
      throw new ApiError(0, error && error.name === 'AbortError' ? MESSAGES.timeout : MESSAGES.network);
    }).finally(function () {
      if (timer) clearTimeout(timer);
    });
  }

  function loginErrorMessage(error) {
    if (!(error instanceof ApiError)) return MESSAGES.server;
    if (error.status === 0) return error.message;
    if (error.status === 401) return MESSAGES.badCredentials;
    if (error.status === 429) return error.message || MESSAGES.tooManyAttempts;
    if (error.status === 400 && error.message) return error.message;
    return MESSAGES.server;
  }

  // ---- UI helpers ----

  function showAlert(element, message) {
    element.textContent = message;
    element.hidden = !message;
  }

  function setFieldError(input, message) {
    var error = $(input.id + '-error');
    error.textContent = message || '';
    error.hidden = !message;
    if (message) input.setAttribute('aria-invalid', 'true');
    else input.removeAttribute('aria-invalid');
  }

  function setBusy(button, isBusy, label) {
    button.classList.toggle('is-busy', isBusy);
    button.querySelector('.button-label').textContent = label;
    button.setAttribute('aria-busy', String(isBusy));
  }

  function validate() {
    var email = emailInput.value.trim();
    var ok = true;
    var firstInvalid = null;

    if (!email) {
      setFieldError(emailInput, 'Enter your email.');
      ok = false;
      firstInvalid = emailInput;
    } else if (!EMAIL_PATTERN.test(email)) {
      setFieldError(emailInput, 'Enter a valid email, like you@example.com.');
      ok = false;
      firstInvalid = emailInput;
    } else {
      setFieldError(emailInput, '');
    }

    if (!passwordInput.value) {
      setFieldError(passwordInput, 'Enter your password.');
      ok = false;
      firstInvalid = firstInvalid || passwordInput;
    } else {
      setFieldError(passwordInput, '');
    }

    if (firstInvalid) firstInvalid.focus();
    return ok;
  }

  function setFormDisabled(disabled) {
    emailInput.disabled = disabled;
    passwordInput.disabled = disabled;
    togglePassword.disabled = disabled;
    continueButton.disabled = disabled;
  }

  // ---- Step 1: sign in ----

  loginForm.addEventListener('submit', function (event) {
    event.preventDefault();
    if (busy) return;
    showAlert(formAlert, '');
    if (!validate()) return;

    var email = emailInput.value.trim();
    busy = true;
    setFormDisabled(true);
    setBusy(continueButton, true, 'Checking…');

    request('/auth/login', { method: 'POST', body: { email: email, password: passwordInput.value } })
      .then(function (data) {
        if (!data || typeof data.accessToken !== 'string' || !data.accessToken) {
          throw new ApiError(500, null);
        }
        session = { token: data.accessToken, email: email };
        openConfirm();
      })
      .catch(function (error) {
        showAlert(formAlert, loginErrorMessage(error));
        if (error instanceof ApiError && error.status === 401) {
          passwordInput.value = '';
        }
      })
      .finally(function () {
        busy = false;
        setFormDisabled(false);
        setBusy(continueButton, false, 'Continue');
        if (!session) (passwordInput.value ? emailInput : passwordInput).focus();
      });
  });

  emailInput.addEventListener('input', function () { setFieldError(emailInput, ''); });
  passwordInput.addEventListener('input', function () { setFieldError(passwordInput, ''); });

  togglePassword.addEventListener('click', function () {
    var show = passwordInput.type === 'password';
    passwordInput.type = show ? 'text' : 'password';
    togglePassword.setAttribute('aria-pressed', String(show));
    togglePassword.setAttribute('aria-label', show ? 'Hide password' : 'Show password');
    passwordInput.focus();
  });

  // ---- Step 2: confirm ----

  function openConfirm() {
    confirmEmail.textContent = session.email;
    confirmCheck.checked = false;
    confirmCheck.disabled = false;
    deleteButton.disabled = true;
    cancelButton.disabled = false;
    showAlert(confirmAlert, '');
    if (typeof dialog.showModal === 'function') dialog.showModal();
    else dialog.setAttribute('open', '');
    // Safe default: focus lands on Cancel, not on the destructive action.
    cancelButton.focus();
  }

  function closeConfirm() {
    if (typeof dialog.close === 'function') dialog.close();
    else dialog.removeAttribute('open');
  }

  function cancelConfirm() {
    if (busy) return;
    session = null;
    closeConfirm();
    passwordInput.focus();
  }

  confirmCheck.addEventListener('change', function () {
    deleteButton.disabled = !confirmCheck.checked;
  });

  cancelButton.addEventListener('click', cancelConfirm);

  // Escape key: same as Cancel, but not while the delete is in flight.
  dialog.addEventListener('cancel', function (event) {
    event.preventDefault();
    cancelConfirm();
  });

  deleteButton.addEventListener('click', function () {
    if (busy || !session || !confirmCheck.checked) return;
    busy = true;
    showAlert(confirmAlert, '');
    cancelButton.disabled = true;
    confirmCheck.disabled = true;
    deleteButton.disabled = true;
    setBusy(deleteButton, true, 'Deleting…');

    request('/auth/delete-user', { method: 'DELETE', token: session.token })
      .then(function (data) {
        if (!data || data.deleted !== true) throw new ApiError(500, null);
        busy = false;
        session = null;
        closeConfirm();
        showDone();
      })
      .catch(function (error) {
        busy = false;
        var status = error instanceof ApiError ? error.status : 500;
        if (status === 401 || status === 404) {
          // The token no longer works (expired, or the account is gone): back to sign-in.
          session = null;
          closeConfirm();
          passwordInput.value = '';
          showAlert(formAlert, status === 401 ? MESSAGES.sessionExpired : MESSAGES.alreadyDeleted);
          passwordInput.focus();
          return;
        }
        // Nothing was deleted; let the user retry or cancel.
        showAlert(confirmAlert, status === 0 ? error.message : MESSAGES.server);
        cancelButton.disabled = false;
        confirmCheck.disabled = false;
        deleteButton.disabled = !confirmCheck.checked;
      })
      .finally(function () {
        setBusy(deleteButton, false, 'Delete account');
      });
  });

  // ---- Step 3: done ----

  function showDone() {
    loginForm.reset();
    formView.hidden = true;
    footer.hidden = true;
    doneView.hidden = false;
    doneView.focus();
  }
})();
