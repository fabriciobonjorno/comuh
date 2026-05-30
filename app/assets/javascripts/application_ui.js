(function () {
  var USERNAME_KEYS = ["comuh_current_username", "comuh_username"];

  function csrfToken() {
    var meta = document.querySelector("meta[name='csrf-token']");
    return meta && meta.content;
  }

  function storedUsername() {
    if (!window.localStorage) return null;

    for (var index = 0; index < USERNAME_KEYS.length; index += 1) {
      var username = window.localStorage.getItem(USERNAME_KEYS[index]);
      if (username) return username;
    }

    return null;
  }

  function rememberUsername(username) {
    if (!username || !window.localStorage) return;

    var normalized = username.trim().toLowerCase();
    if (!normalized) return;

    USERNAME_KEYS.forEach(function (key) {
      window.localStorage.setItem(key, normalized);
    });

    syncUsernameFields(normalized);
  }

  function syncUsernameFields(username) {
    if (!username) return;

    document.querySelectorAll('input[name="username"]').forEach(function (input) {
      input.value = username;
    });
  }

  function hydrateUsernameFields(root) {
    var username = storedUsername();
    if (!username) return;

    (root || document).querySelectorAll('input[name="username"]').forEach(function (input) {
      if (input.value === "") {
        input.value = username;
      }
    });
  }

  function usernameFromPage() {
    var input = document.querySelector('input[name="username"]');
    var value = input && input.value && input.value.trim();

    if (value) {
      rememberUsername(value);
      return value.toLowerCase();
    }

    return storedUsername();
  }

  function requestUsername() {
    var modal = document.getElementById("username-modal");
    var input = document.getElementById("username-modal-input");
    var form = document.getElementById("username-modal-form");
    var cancel = document.getElementById("username-modal-cancel");
    var backdrop = document.getElementById("username-modal-backdrop");
    var error = document.getElementById("username-modal-error");

    if (!modal || !input || !form || !cancel || !backdrop || !error) {
      var prompted = window.prompt("Choose a username", storedUsername() || "");
      rememberUsername(prompted);
      return Promise.resolve(prompted);
    }

    return new Promise(function (resolve, reject) {
      function cleanup() {
        form.removeEventListener("submit", submit);
        cancel.removeEventListener("click", dismiss);
        backdrop.removeEventListener("click", dismiss);
        modal.classList.add("hidden");
      }

      function submit(event) {
        event.preventDefault();

        var username = input.value.trim().toLowerCase();
        if (!username) {
          error.textContent = "Please enter a username.";
          error.classList.remove("hidden");
          input.focus();
          return;
        }

        rememberUsername(username);
        cleanup();
        resolve(username);
      }

      function dismiss() {
        cleanup();
        reject(new Error("cancelled"));
      }

      input.value = storedUsername() || "";
      error.textContent = "";
      error.classList.add("hidden");
      modal.classList.remove("hidden");
      setTimeout(function () { input.focus(); }, 50);

      form.addEventListener("submit", submit);
      cancel.addEventListener("click", dismiss);
      backdrop.addEventListener("click", dismiss);
    });
  }

  function headers() {
    var token = csrfToken();
    var values = {
      "Accept": "application/json",
      "Content-Type": "application/json"
    };

    if (token) {
      values["X-CSRF-Token"] = token;
    }

    return values;
  }

  function formPayload(form) {
    var data = new FormData(form);
    var payload = {};

    data.forEach(function (value, key) {
      if (value !== "") {
        payload[key] = value;
      }
    });

    return payload;
  }

  async function submitMessage(form) {
    var status = form.querySelector("[data-message-form-target='status']");
    var target = document.getElementById(form.dataset.messageFormTargetIdValue);
    var payload = formPayload(form);

    if (status) {
      status.textContent = "Posting...";
    }

    var response = await fetch(form.dataset.messageFormUrlValue, {
      method: "POST",
      headers: headers(),
      body: JSON.stringify(payload)
    });
    var body = await response.json();

    if (!response.ok) {
      if (status) {
        status.textContent = body.error || "Unable to post message";
      }
      return;
    }

    rememberUsername(payload.username || (body.user && body.user.username));

    if (target && body.html) {
      target.insertAdjacentHTML("afterbegin", body.html);
      hydrateUsernameFields(target);
    }

    var content = form.querySelector("[data-message-form-target='content']");
    if (content) {
      content.value = "";
    }
    if (status) {
      status.textContent = "";
    }
  }

  async function submitReaction(container, type) {
    var status = container.querySelector("[data-reaction-target='status']");
    var username = usernameFromPage();

    if (!username) {
      try {
        username = await requestUsername();
      } catch (error) {
        username = null;
      }
    }

    if (!username) {
      if (status) {
        status.textContent = "Username required";
      }
      return;
    }

    var response = await fetch(container.dataset.reactionUrlValue, {
      method: "POST",
      headers: headers(),
      body: JSON.stringify({
        message_id: container.dataset.reactionMessageIdValue,
        username: username,
        reaction_type: type
      })
    });
    var body = await response.json();

    if (!response.ok) {
      if (status) {
        status.textContent = body.error || "Unable to react";
      }
      return;
    }

    ["like", "love", "insightful"].forEach(function (reactionType) {
      var count = container.querySelector("[data-reaction-target='" + reactionType + "Count']");
      if (count) {
        count.textContent = body.reactions[reactionType] || 0;
      }
    });

    if (status) {
      status.textContent = "";
    }
  }

  document.addEventListener("submit", function (event) {
    var form = event.target.closest("[data-controller='message-form']");
    if (!form) {
      return;
    }

    event.preventDefault();
    submitMessage(form);
  });

  document.addEventListener("click", function (event) {
    var button = event.target.closest("[data-action='reaction#react']");
    if (!button) {
      return;
    }

    var container = button.closest("[data-controller='reaction']");
    if (!container) {
      return;
    }

    event.preventDefault();
    submitReaction(container, button.dataset.reactionTypeParam);
  });

  document.addEventListener("input", function (event) {
    if (event.target.matches('input[name="username"]') && event.target.value.trim() !== "") {
      rememberUsername(event.target.value);
    }
  });

  document.addEventListener("DOMContentLoaded", function () {
    hydrateUsernameFields(document);
  });
})();
