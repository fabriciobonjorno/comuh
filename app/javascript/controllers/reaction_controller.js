import { Controller } from "@hotwired/stimulus"

// Matches the server-side User username format validation.
const USERNAME_RE = /^[a-z0-9][a-z0-9_-]*$/

const STORAGE_KEYS = {
  userId: "comuh_current_user_id",
  username: "comuh_current_username"
}

// Connects to data-controller="reaction"
export default class extends Controller {
  static targets = ["likeCount", "loveCount", "insightfulCount", "status"]

  static values = {
    url: String,
    messageId: String
  }

  connect() {
    this.reactionRecoveryAttempted = false
  }

  async react(event) {
    event.preventDefault()

    const reactionType = event.params.type
    this.setStatus("Saving...")

    await this.submitReaction(reactionType)
  }

  async submitReaction(reactionType) {
    let userId = localStorage.getItem(STORAGE_KEYS.userId)
    let username = localStorage.getItem(STORAGE_KEYS.username)

    if (!userId) {
      try {
        username = await this.requireUsername()
        userId = await this.findOrCreateUser(username)
      } catch {
        this.setStatus("Username required to react")
        return
      }
    }

    if (!userId) {
      this.setStatus("Username required to react")
      return
    }

    const payload = {
      message_id: this.messageIdValue,
      user_id: userId,
      username: username,
      reaction_type: reactionType
    }

    let response
    let data

    try {
      response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken()
        },
        body: JSON.stringify(payload)
      })

      data = await response.json()
    } catch {
      this.setStatus("Network error saving reaction")
      return
    }

    if (!response.ok) {
      await this.handleReactionError(response, data, reactionType)
      return
    }

    this.updateCounts(data.reactions)

    this.reactionRecoveryAttempted = false
    this.setStatus("✓ Saved")
    setTimeout(() => this.setStatus(""), 2000)
  }

  async handleReactionError(response, data, reactionType) {
    if (response.status === 404 && data.code === "user_not_found" && !this.reactionRecoveryAttempted) {
      this.reactionRecoveryAttempted = true
      this.clearStoredUser()

      try {
        const freshUsername = await this.requireUsername()
        await this.findOrCreateUser(freshUsername)
        return this.submitReaction(reactionType)
      } catch {
        this.setStatus("Username required to react")
        return
      }
    }

    if (response.status === 404 && data.code === "message_not_found") {
      this.setStatus("Message not found")
      return
    }

    if (response.status === 409) {
      this.setStatus(data.error || "Reaction already exists")
      return
    }

    this.setStatus(data.error || "Error saving reaction")
  }

  async findOrCreateUser(username) {
    const response = await fetch("/api/v1/users", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": this.csrfToken()
      },
      body: JSON.stringify({ username })
    })

    const data = await response.json()

    if (!response.ok) {
      this.clearStoredUser()
      throw new Error(data.error || "Unable to create user")
    }

    const user = data.user || data

    if (!user.id || !user.username) {
      this.clearStoredUser()
      throw new Error("Invalid user response")
    }

    localStorage.setItem(STORAGE_KEYS.username, user.username)
    localStorage.setItem(STORAGE_KEYS.userId, user.id)

    return user.id
  }

  requireUsername() {
    const saved = localStorage.getItem(STORAGE_KEYS.username)
    if (saved) return Promise.resolve(saved)

    return new Promise((resolve, reject) => {
      const modal = document.getElementById("username-modal")
      const input = document.getElementById("username-modal-input")
      const form = document.getElementById("username-modal-form")
      const cancelBtn = document.getElementById("username-modal-cancel")
      const backdrop = document.getElementById("username-modal-backdrop")
      const error = document.getElementById("username-modal-error")

      if (!modal || !input || !form || !cancelBtn || !backdrop || !error) {
        reject(new Error("Username modal is missing from the DOM"))
        return
      }

      modal.classList.remove("hidden")
      input.value = ""
      error.textContent = ""
      error.classList.add("hidden")
      setTimeout(() => input.focus(), 50)

      const cleanup = () => {
        form.removeEventListener("submit", onSubmit)
        cancelBtn.removeEventListener("click", onCancel)
        backdrop.removeEventListener("click", onCancel)
        modal.classList.add("hidden")
      }

      const onSubmit = (event) => {
        event.preventDefault()

        const value = input.value.trim().toLowerCase()

        if (!value) {
          this.showModalError(error, input, "Please enter a username.")
          return
        }

        if (!USERNAME_RE.test(value)) {
          this.showModalError(
            error,
            input,
            "Only letters, numbers, hyphens and underscores — no spaces."
          )
          return
        }

        localStorage.setItem(STORAGE_KEYS.username, value)
        cleanup()
        resolve(value)
      }

      const onCancel = () => {
        cleanup()
        reject(new Error("cancelled"))
      }

      form.addEventListener("submit", onSubmit)
      cancelBtn.addEventListener("click", onCancel)
      backdrop.addEventListener("click", onCancel)
    })
  }

  updateCounts(reactions = {}) {
    this.likeCountTarget.textContent = reactions.like || 0
    this.loveCountTarget.textContent = reactions.love || 0
    this.insightfulCountTarget.textContent = reactions.insightful || 0
  }

  showModalError(error, input, message) {
    error.textContent = message
    error.classList.remove("hidden")
    input.focus()
  }

  clearStoredUser() {
    localStorage.removeItem(STORAGE_KEYS.userId)
    localStorage.removeItem(STORAGE_KEYS.username)
  }

  setStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
    }
  }

  csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
  }
}