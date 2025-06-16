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

	// Initial timer for this timer's first loop
	float InitialTime;

	// Whether or not this timer is set to be paused initially
	bool InitiallyPaused;

	// Whether or not this timer is looping
	bool Looping;
	
	// Stored timer value for when timer is paused
	float PausedValue;
	
	// Whether or not this timer is paused
	bool Paused;

	// Whether or not this timer clears after it first expires. Ignored if Looping is set to true
	bool SingleUse;

	/*
	* Sets the timer value but does not activate the timer
	*
	* @param time			Duration for this timer
	* @param startPaused	(default: true) Whether or not this timer should start paused
	* @param loop 			(default: false) Should this timer loop
	* @param singleUse		(default: false) Should this timer clear after it first expires. Ignored if loop is true.
	* @param initialDelay	(default: 0.0) Initial delay passed to the timer
	*/
	void Set(float time, bool startPaused = false, bool loop = false, bool singleUse = false, float initialDelay = 0.0)
	{
		this.Time = time;
		this.InitialTime = time + initialDelay;
		this.Looping = loop;
		this.PausedValue = time;
		this.Paused = startPaused;
		this.InitiallyPaused = startPaused;
		this.SingleUse = singleUse;
		
		if (!this.Paused) // Timer is active
			this.NextTime = GetGameTime() + this.InitialTime;
	}
	
	// Resumes this timer if it is currently paused
	void Continue()
	{
		if (this.Paused)
		{
			if (this.InitiallyPaused)
			{
				this.NextTime = GetGameTime() + this.InitialTime;
				this.InitiallyPaused = false;
			}
			else
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
		if (this.Paused)
			return this.PausedValue;

		float result = this.NextTime - GetGameTime();
		if (result > 0.0)
			return result;
		else
			return 0.0;
	}
	
	// Pauses this timer until FTimer::Continue() is called
	void Pause()
	{
		if (this.Paused)
			return;

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

		if (result)
		{
			if (this.Looping)
				this.NextTime = GetGameTime() + this.Time;
			else if (this.SingleUse)
				this.Clear();
		}

		return result;
	}
}

/*
* Creates a timer and returns its information as an FTimer
*
* @param duration 	Duration for this timer
* @param paused		Should this timer start paused
* @param loop 		Should this timer loop
* @param singleUse	Should this timer clear after it first expires. Ignored if loop is true.
* @param initialDelay	(default: 0.0) Initial delay passed to the timer
*
* @return - FTimer containing this timer's information
*/

stock FTimer ConstructTimer(const float duration, bool paused = true, bool loop = false, bool singleUse = false, float initialDelay = 0.0)
{
	FTimer timer;
	timer.Set(duration, paused, loop, singleUse, initialDelay);

	return timer;
}

/*
 * Object used to track timer variables with methodmaps. Functions the same as FTimer but uses a StringMap instead of a struct.
 */
methodmap STimer < StringMap
{
	/**
	 * Creates a timer connected to a StringMap
	 * 
	 * @param duration		Duration for this timer
	 * @param paused		Is this timer paused initially
	 * @param loop			Whether or not this timer should loop when expired
	 * @param singleUse		If true, this timer will clear itself after it expires. Ignored if looping is set to true.
	 * @param initialDelay	Amount of time to add to the first loop (can be negative).
	 * 
	 * @return 				STimer Handle
	 */
	public STimer(float duration, bool paused = false, bool loop = false, bool singleUse = false, float initialDelay = 0.0)
	{
		StringMap timer = new StringMap();

		timer.SetValue("Time", duration);
		timer.SetValue("InitialTime", duration + initialDelay);
		timer.SetValue("Looping", loop);
		timer.SetValue("PausedTime", duration);
		timer.SetValue("Paused", paused);
		timer.SetValue("InitiallyPaused", paused);
		timer.SetValue("SingleUseTimer", singleUse);

		if (!paused) // Timer is active
			timer.SetValue("NextTimeAt", GetGameTime() + duration + initialDelay);

		return view_as<STimer>(timer);
	}

	property float Duration
	{
		public set(float duration) { this.SetValue("Time", duration); }
		public get() { return this.GetValueFloat("Time"); }
	}

	property float NextTimeAt
	{
		public set(float time) { this.SetValue("NextTimeAt", time); }
		public get() { return this.GetValueFloat("NextTimeAt"); }
	}

	property float InitialTime
	{
		public get() { return this.GetValueFloat("InitialValue"); } 
	}

	property bool Looping
	{
		public set(bool loop) { this.SetValue("Looping", loop); }
		public get() { return this.GetValueBool("Looping"); }
	}

	property float PausedTime
	{
		public set(float time) { this.SetValue("PausedTime", time); }
		public get() { return this.GetValueFloat("PausedTime"); }
	}

	property bool Paused
	{
		public set(bool pause) { this.SetValue("Paused", pause); }
		public get() { return this.GetValueBool("Paused"); }
	}

	property bool InitiallyPaused
	{
		public set(bool pause) { this.SetValue("InitiallyPaused", pause); }
		public get() { return this.GetValueBool("InitiallyPaused"); }
	}

	property bool SingleUse
	{
		public set(bool single) { this.SetValue("SingleUseTimer", single); }
		public get() { return this.GetValueBool("SingleUseTimer"); }
	}

	// Sets the duration for this timer and loops it
	public void SetTimer(float time)
	{
		this.Duration = time;
		this.Loop();
	}
	
	// Resumes this timer if it was started and paused
	public void Continue()
	{
		if (this.Paused)
		{
			if (this.InitiallyPaused)
			{
				this.NextTimeAt = GetGameTime() + this.InitialTime;
				this.InitiallyPaused = false;
			}
			else
				this.NextTimeAt = GetGameTime() + this.PausedTime;
		}
		this.Paused = false;
	}

	// Clears and deactivates this timer
	public void Clear()
	{
		this.NextTimeAt = -1.0;
		this.Looping = false;
		this.PausedTime = -1.0;
	}
	
	// Returns the time remaining on this timer in seconds, or 0 if the timer is not active
	public float GetTimeRemaining()
	{
		if (this.Paused)
			return this.PausedTime;

		float result = this.NextTimeAt - GetGameTime();
		if (result > 0.0)
			return result;
		else
			return 0.0;
	}
	
	// Pauses this timer until STimer::Continue() is called
	public void Pause()
	{
		if (this.Paused)
			return;
			
		this.Paused = true;
		this.PausedTime = this.GetTimeRemaining();
	}

	// Returns the full duration of this timer
	public float GetTimerDuration()
	{
		return this.Duration;
	}

	/*
	* Loops this timer with the last given time input
	*
	* Note - This will unpause the timer if it is paused
	*/
	public void Loop()
	{
		this.NextTimeAt = GetGameTime() + this.Duration;
		this.Paused = false;
	}

	/*
	* Returns whether or not this timer has expired
	* If the timer is marked to loop, it will automatically reset when this is called. Otherwise STimer::Loop() can be used to restart the timer
	*/
	public bool Expired()
	{
		if (this.Paused) // Do nothing if timer is paused
			return false;
			
		bool result = (this.NextTimeAt <= GetGameTime() && this.NextTimeAt != -1.0);

		if (result)
		{
			if (this.Looping)
				this.NextTimeAt = GetGameTime() + this.Duration;
			else if (this.SingleUse)
				this.Clear();
		}

		return result;
	}

	public float GetValueFloat(const char[] key)
	{
		float value = 0.0;
		this.GetValue(key, value);

		return value;
	}

	public bool GetValueBool(const char[] key)
	{
		bool value = false;
		this.GetValue(key, value);

		return value;
	}
}
