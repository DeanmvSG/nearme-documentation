class FlashMessagesLinks {
  constructor(alert) {
    this.alert = alert;
    this.link = this.alert.querySelector('a[href]:not(.close)');
    this.hasLinkToFollow = this.link !== null;

    if (this.hasLinkToFollow) {
      this._attachEventHandlers();
    }
  }

  _followFirstLink(event) {
    var clickedCloseButton = event.target.classList.contains('close'); // in case someone wants to just close it
    var clickedOtherLink = event.target.href && event.target.href !== this.link.href; // in case someone clicks a different link in alert

    if (!clickedCloseButton && !clickedOtherLink) {
      window.location.href = this.link.href;
    }
  }

  _attachEventHandlers() {
    this.alert.addEventListener('click', this._followFirstLink.bind(this));
  }
}

module.exports = FlashMessagesLinks;