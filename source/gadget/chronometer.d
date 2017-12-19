module gadget.chronometer;

import derelict.sfml2.system;

class Chronometer {
	this() {
		m_clock = sfClock_create();
		restart();
	}

	sfTime add(sfTime time) {
		m_time += sfTime_asSeconds(time);

		if (m_state == State.STOPPED) m_state = State.PAUSED;

		return getElapsedTime();
	}

	sfTime restart() {
		sfTime time = getElapsedTime();

		m_time = 0;
		m_state = State.RUNNING;
		sfClock_restart(m_clock);

		return time;
	}

	sfTime pause() {
		if (isRunning()) {
			m_state = State.PAUSED;
			m_time += sfTime_asSeconds(sfClock_getElapsedTime(m_clock));
		}
		return getElapsedTime();
	}

	sfTime resume() {
		if (!isRunning()) {
			m_state = State.RUNNING;
			sfClock_restart(m_clock);
		}
		return getElapsedTime();
	}

	sfTime toggle() {
		if (isRunning())
			pause();
		else
			resume();

		return getElapsedTime();
	}

	bool isRunning() const {
		return m_state == State.RUNNING;
	}

	sfTime getElapsedTime() const {
		final switch (m_state) {
		case State.STOPPED:
			return sfTime_Zero;

		case State.RUNNING:
			return sfSeconds(m_time + m_timeScale * sfTime_asSeconds(sfClock_getElapsedTime(m_clock)));

		case State.PAUSED:
			return sfSeconds(m_time);
		}
	}

	void setTimeScale(float scale) {
		m_timeScale = scale;
	}

private:
	enum State { STOPPED, RUNNING, PAUSED }
	State m_state;
	float m_time;
	sfClock* m_clock;
	float m_timeScale = 1f;
}
