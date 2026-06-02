import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="message-form"
export default class extends Controller {
  static targets = ["username", "content", "status"]

  static values = {
    url: String,
    targetId: String
  }

  connect() {
    const saved = localStorage.getItem("comuh_current_username")
    if (saved && this.usernameTarget.value === "") {
      this.usernameTarget.value = saved
    }

    this.usernameTarget.addEventListener("input", this.rememberTypedUsername)
  }

  disconnect() {
    this.usernameTarget.removeEventListener("input", this.rememberTypedUsername)
  }

  async submit(event) {
    event.preventDefault()

    this.statusTarget.textContent = "Sending..."

    const formData = new FormData(this.element)

    const payload = {
      username: formData.get("username"),
      community_id: formData.get("community_id"),
      parent_message_id: formData.get("parent_message_id") || null,
      content: formData.get("content"),
      user_ip: formData.get("user_ip")
    }

    const postUrl = this.urlValue || this.element.action || '/api/v1/messages'

    const response = await fetch(postUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": this.csrfToken()
      },
      body: JSON.stringify(payload)
    })

    const data = await response.json()

    if (!response.ok) {
      this.statusTarget.textContent = data.error || "Error creating message"
      return
    }

    // support both { message: {...}, html: '...' } and flat { id:..., user: {...}, html: '...'}
    const payloadMessage = data.message ? data.message : data
    if (payloadMessage && payloadMessage.user) {
      this.rememberUsername(payloadMessage.user.username)
      localStorage.setItem("comuh_current_user_id", payloadMessage.user.id)
    }

    this.contentTarget.value = ""
    this.statusTarget.textContent = "Message created successfully"
  }

  csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
  }

  rememberTypedUsername = (event) => {
    this.rememberUsername(event.target.value)
  }

  rememberUsername(username) {
    const normalized = username.trim().toLowerCase()
    if (!normalized) return

    localStorage.setItem("comuh_current_username", normalized)
    document.querySelectorAll('input[name="username"]').forEach((input) => {
      input.value = normalized
    })
  }
}
