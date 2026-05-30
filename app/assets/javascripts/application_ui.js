(function () {
  function csrfToken() {
    var meta = document.querySelector("meta[name='csrf-token']");
    return meta && meta.content;
  }

  function storedUsername() {
    return window.localStorage && window.localStorage.getItem("comuh_username");
  }

  function rememberUsername(username) {
    if (username && window.localStorage) {
      window.localStorage.setItem("comuh_username", username);
    }
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

    rememberUsername(payload.username);

    if (target && body.html) {
      target.insertAdjacentHTML("afterbegin", body.html);
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
    var username = storedUsername();

    if (!username) {
      username = window.prompt("Choose a username");
      rememberUsername(username);
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
})();
