#if defined _ilib_timer_included
 #endinput
#endif
#define _ilib_timer_included

/*
* Struct used to create pseudo timers
* Used with GetGameTime() to determine if the timer has expired
*/
enum struct FTimer
{
	// Game time when this timer will expire next
	float NextTime;

	// Timer value to use for this timer
	float Time;

	// Whether or not this timer is looping
	bool Looping;
	
	// Stored timer value for when timer is paused
	float PausedValue;
	
	// Whether or not this timer is paused
	bool Paused;

	/*
	* Sets the timer value but does not activate the timer
	*
	* @param time			Duration for this timer
	* @param startPaused	(default: true) Whether or not this timer should start paused
	* @param loop 			(default: false) Should this timer loop
	*/
	void Set(float time, bool startPaused = true, bool loop = false)
	{
		this.Time = time;
		this.Looping = loop;
		this.PausedValue = time;
		this.Paused = startPaused;
		
		if (!this.Paused) // Timer is active
			this.NextTime = GetGameTime() + this.Time;
	}
	
	// Starts or resumes this timer
	void Continue()
	{
		if (this.Paused)
		{
			this.NextTime = GetGameTime() + this.PausedValue;
			this.Paused = false;
		}
	}

	// Clears and deactivates this timer
	void Clear()
	{
		this.NextTime = -1.0;
		this.Looping = false;
		this.PausedValue = -1.0;
	}
	
	// Returns the timr remaining on this timer in seconds, or 0 if the timer is not active
	float GetTimeRemaining()
	{
		float result = this.NextTime - GetGameTime();
		if (result > 0.0)
			return result;
		else
			return 0.0;
	}
	
	// Pauses this timer until FTimer::Continue() is called
	void Pause()
	{
		this.Paused = true;
		this.PausedValue = this.GetTimeRemaining();
	}

	// Returns the full duration of this timer
	float GetTimerDuration()
	{
		return this.Time;
	}

	/*
	* Loops this timer with the last given time input
	*
	* Note - This will unpause the timer if it is paused
	*/
	void Loop()
	{
		this.NextTime = GetGameTime() + this.Time;
		this.Paused = false;
	}

	/*
	* Returns whether or not this timer has expired
	* If the timer is marked to loop, it will automatically reset when this is called. Otherwise FTimer::Loop() can be used to restart the timer
	*/
	bool Expired()
	{
		if (this.Paused) // Do nothing if timer is paused
			return false;
			
		bool result = (this.NextTime <= GetGameTime() && this.NextTime != -1.0);

		if (this.Looping && result)
			this.NextTime = GetGameTime() + this.Time;

		return result;
	}
}

/*
* Creates a timer and returns its information as an FTimer
*
* @param duration 	Duration for this timer
* @param paused		Should this timer start paused
* @param loop 		Should this timer loop
*
* @return - FTimer containing this timer's information
*/

stock FTimer ConstructTimer(float duration, bool paused = true, bool loop = false)
{
	FTimer timer;
	timer.Set(duration, paused, loop);

	return timer;
}
