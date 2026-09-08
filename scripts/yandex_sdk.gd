extends Node

# Yandex Games SDK integration for Godot Web export

signal sdk_initialized()
signal reward_earned(reward_type: String, reward_value: String)
signal reward_error(error: String)
signal data_saved()
signal data_loaded(data: Dictionary)

var is_initialized: bool = false
var is_web: bool = false
var ysdk = null  # JavaScript object reference

func _ready():
	# Only initialize on web platform
	if OS.has_feature("web"):
		is_web = true
		_init_sdk()
	else:
		# Fallback for local testing
		print("[YandexSDK] Not on web platform, using local fallback")
		is_initialized = true
		sdk_initialized.emit()

func _init_sdk():
	# Check if Yandex SDK is available
	if not JavaScriptBridge.has_method("eval"):
		print("[YandexSDK] JavaScriptBridge not available")
		is_initialized = true
		sdk_initialized.emit()
		return
	
	# Initialize Yandex SDK
	JavaScriptBridge.eval("""
		if (window.YaGames) {
			window.YaGames.init().then(ysdk => {
				window.ysdk = ysdk;
				window.ysdk_ready = true;
				console.log('[YandexSDK] Initialized');
			}).catch(err => {
				console.error('[YandexSDK] Init failed:', err);
				window.ysdk_ready = false;
			});
		} else {
			console.warn('[YandexSDK] YaGames not found');
			window.ysdk_ready = false;
		}
	""")
	
	# Poll for initialization
	var poll_timer = Timer.new()
	poll_timer.wait_time = 0.5
	poll_timer.autostart = true
	add_child(poll_timer)
	
	var attempts = 0
	poll_timer.timeout.connect(func():
		attempts += 1
		var ready = JavaScriptBridge.eval("window.ysdk_ready === true")
		if ready:
			is_initialized = true
			poll_timer.stop()
			poll_timer.queue_free()
			sdk_initialized.emit()
			print("[YandexSDK] Ready!")
		elif attempts > 10:
			# Timeout - use fallback
			is_initialized = true
			poll_timer.stop()
			poll_timer.queue_free()
			sdk_initialized.emit()
			print("[YandexSDK] Timeout, using fallback")
	)

# Save game data
func save_data(data: Dictionary) -> bool:
	if not is_web:
		_save_local(data)
		return true
	
	var json_str = JSON.stringify(data)
	JavaScriptBridge.eval("""
		if (window.ysdk && window.ysdk.getPlayer) {
			window.ysdk.getPlayer().then(player => {
				player.setData(%s).then(() => {
					console.log('[YandexSDK] Data saved');
				}).catch(err => {
					console.error('[YandexSDK] Save failed:', err);
					localStorage.setItem('game_save', '%s');
				});
			}).catch(() => {
				localStorage.setItem('game_save', '%s');
			});
		} else {
			localStorage.setItem('game_save', '%s');
		}
	""" % [json_str, json_str, json_str, json_str])
	
	data_saved.emit()
	return true

# Load game data
func load_data() -> Dictionary:
	if not is_web:
		return _load_local()
	
	# Try to load from localStorage first (synchronous)
	var local_data = JavaScriptBridge.eval("localStorage.getItem('game_save')")
	if local_data and local_data != "null":
		var json = JSON.new()
		if json.parse(local_data) == OK:
			return json.data
	
	# Try async Yandex SDK load
	JavaScriptBridge.eval("""
		if (window.ysdk && window.ysdk.getPlayer) {
			window.ysdk.getPlayer().then(player => {
				player.getData().then(data => {
					if (data && Object.keys(data).length > 0) {
						localStorage.setItem('game_save', JSON.stringify(data));
					}
				});
			});
		}
	""")
	
	return {}

func _save_local(data: Dictionary):
	var file = FileAccess.open("user://save.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func _load_local() -> Dictionary:
	var file = FileAccess.open("user://save.json", FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(content) == OK:
			return json.data
	return {}

# Rewarded video
func show_rewarded_video(reward_type: String = "coins", reward_amount: int = 50):
	if not is_web:
		# Fallback for testing - give reward immediately
		_give_reward(reward_type, reward_amount)
		return
	
	JavaScriptBridge.eval("""
		if (window.ysdk && window.ysdk.adv) {
			window.ysdk.adv.showRewardedVideo({
				callbacks: {
					onOpen: () => { console.log('[YandexSDK] Ad opened'); },
					onRewarded: (data) => { 
						console.log('[YandexSDK] Rewarded:', data);
						window.yandex_reward = true;
					},
					onClose: () => { 
						console.log('[YandexSDK] Ad closed');
						if (window.yandex_reward) {
							window.yandex_reward = false;
						}
					},
					onError: (e) => { console.error('[YandexSDK] Ad error:', e); }
				}
			});
		} else {
			// Fallback
			window.yandex_reward = true;
		}
	""")
	
	# Poll for reward
	var poll_timer = Timer.new()
	poll_timer.wait_time = 0.5
	poll_timer.autostart = true
	add_child(poll_timer)
	
	var attempts = 0
	poll_timer.timeout.connect(func():
		attempts += 1
		var got_reward = JavaScriptBridge.eval("window.yandex_reward === true")
		if got_reward:
			JavaScriptBridge.eval("window.yandex_reward = false")
			_give_reward(reward_type, reward_amount)
			poll_timer.stop()
			poll_timer.queue_free()
		elif attempts > 60:  # 30 second timeout
			reward_error.emit("Ad timeout")
			poll_timer.stop()
			poll_timer.queue_free()
	)

func _give_reward(reward_type: String, reward_amount: int):
	match reward_type:
		"coins":
			GameData.coins += reward_amount
			GameData.notify_coins_changed()
		"heal":
			var players = get_tree().get_nodes_in_group("player")
			if players.size() > 0:
				players[0].heal(reward_amount)
		"backpack":
			GameData.current_backpack = 0  # Clear backpack
	
	reward_earned.emit(reward_type, str(reward_amount))

# Interstitial ad
func show_interstitial():
	if not is_web:
		return
	
	JavaScriptBridge.eval("""
		if (window.ysdk && window.ysdk.adv) {
			window.ysdk.adv.showFullscreenAdv({
				callbacks: {
					onClose: () => { console.log('[YandexSDK] Interstitial closed'); },
					onError: (e) => { console.error('[YandexSDK] Interstitial error:', e); }
				}
			});
		}
	""")

# Leaderboard
func submit_score(board_id: String, score: int):
	if not is_web:
		return
	
	JavaScriptBridge.eval("""
		if (window.ysdk && window.ysdk.getLeaderboards) {
			window.ysdk.getLeaderboards().then(lb => {
				lb.setLeaderboardScore('%s', %d);
			});
		}
	""" % [board_id, score])
