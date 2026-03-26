import countdown from 'countdown';

export const Countdown = {
  mounted() {
    const rawEndTimestamp = this.el.dataset.endTimestamp;
    if (!rawEndTimestamp) {
      return;
    }

    const endTimestamp = new Date(Number.parseInt(rawEndTimestamp));
    this.timerId = countdown((ts) => {
      if (ts.value < 0) {
        this.el.textContent = this.el.dataset.countdownOver;
        this.pushEvent("countdown-over", { id: this.el.id });
        this.destroyed();
        return;
      }

      let countdownText = ts.toString();
      if (countdownText.length === 0) {
        countdownText = "0 seconds";
      }
      this.el.textContent = this.el.dataset.countdownTemplate.replace("{{countdown}}", countdownText);
    }, endTimestamp, countdown.HOURS | countdown.MINUTES | countdown.SECONDS, 2);
  },
  destroyed() {
    if (this.timerId) {
      window.clearInterval(this.timerId)
    }
  },
  updated() {
    this.destroyed()
    this.mounted();
  }
};