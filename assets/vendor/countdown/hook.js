import countdown from 'countdown';

export const Countdown = {
  mounted() {
    const rawEndTimestamp = this.el.dataset.endTimestamp;
    if (!rawEndTimestamp) {
      return;
    }
    
    const endTimestamp = new Date(Number.parseInt(rawEndTimestamp));
    this.timerId = countdown((ts) => {
      this.el.textContent = ts.toString();
    }, endTimestamp, countdown.HOURS | countdown.MINUTES | countdown.SECONDS, 2);
  },
  destroyed() {
    if (this.timerId) {
      window.clearInterval(this.timerId)
    }
  }
};