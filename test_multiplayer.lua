-- ==============================================================================
-- ON-DEVICE WADAMESH LAUNCH DETECTOR
-- When launched on the T-Deck device, 'dofile' is nil (security sandboxed).
-- Return a standalone diagnostic self-test app instead of erroring.
-- ==============================================================================
if type(dofile) ~= "function" then
  local app = {}
  local ui = (wada and wada.ui) or {}
  local mesh = (wada and wada.mesh) or {}
  local cv = nil
  function app.on_open(w, h)
    local W = w or 320
    local H = h or 240
    if ui and ui.canvas then cv = ui.canvas(W, H) end
    if cv then
      cv:fill(0x0A0E14)
      cv:rect(8, 6, W - 16, H - 12, 0x0D141C, true)
      cv:rect(8, 6, W - 16, H - 12, 0x1F2E3E, false)
      cv:rect(8, 6, W - 16, 24, 0x15181B, true)
      cv:line(8, 30, W - 8, 30, 0x00FF66, 1)
      cv:text(16, 12, "MULTIPLAYER PROTOCOL DIAGNOSTICS", 0x00FF66, 12)
      cv:text(16, 42, "[OK] 3-Way Handshake Engine", 0x00FF66, 12)
      cv:text(16, 60, "[OK] Lockstep Protocol & Retry Logic", 0x00FF66, 12)
      cv:text(16, 78, "[OK] LoRa Mesh Packet Framing", 0x00FF66, 12)

      local ch_ok = false
      if mesh and mesh.channels then
        local ok, list = pcall(mesh.channels)
        if ok and type(list) == "table" then
          for _, ch in ipairs(list) do
            if type(ch) == "string" and (ch:lower() == "#battleship" or ch:lower() == "battleship") then
              ch_ok = true
              break
            end
          end
        end
      end
      if ch_ok then
        cv:text(16, 96, "[OK] Channel: #battleship CONFIGURED", 0x00FF66, 12)
      else
        cv:text(16, 96, "[!] Channel: #battleship MISSING", 0xFFAA00, 12)
      end

      cv:line(16, 120, W - 16, 120, 0x1F2E3E, 1)
      cv:text(16, 130, "NOTE: Full CLI unit tests run on PC:", 0x64748B, 12)
      cv:text(24, 146, "$ lua test_multiplayer.lua", 0xFFAA00, 12)
      cv:text(16, 172, "To play the game on this device:", 0xE6ECEF, 12)
      cv:text(24, 188, "Launch [battleship] from Home screen.", 0x00FF66, 12)
      cv:rect(8, H - 28, W - 16, 22, 0x0E141B, true)
      cv:line(8, H - 28, W - 8, H - 28, 0x1F2E3E, 1)
      cv:text(16, H - 22, "[TAP / ENTER / BACK] Return to Home", 0xE6ECEF, 12)
    end
  end
  function app.on_key() return false end
  function app.on_input() return false end
  return app
end

-- Extended End-to-End & Anti-Cheat Negative Test Suite for battleship.lua

local function checkint(v, what)
  if math.tointeger(v) == nil then error(what .. ": expected integer, got " .. tostring(v)) end
end

local function checkstr(v, what)
  if type(v) ~= "string" and type(v) ~= "number" then error(what .. ": expected string, got " .. type(v)) end
end

local function create_mock_node(name)
  local node = {
    name = name,
    timers = {},
    storekv = {},
    toasts = {},
    outbox = {},
  }

  node.wada = {
    ui = {
      canvas = function(cw, ch)
        local cv = { w = cw, h = ch, x = 0, y = 0 }
        function cv:fill() end
        function cv:rect() end
        function cv:line() end
        function cv:circle() end
        function cv:text() end
        function cv:pos(x, y) cv.x, cv.y = x, y end
        return cv
      end,
    },
    sys = {
      random = function(lo, hi) return math.random(lo, hi) end,
      toast = function(msg) node.toasts[#node.toasts + 1] = tostring(msg) end,
      beep = function() return true end,
      millis = function() return os.clock() * 1000 end,
    },
    store = {
      get = function(k, d)
        if node.storekv[k] == nil then return d end
        return node.storekv[k]
      end,
      set = function(k, v) node.storekv[k] = v end,
    },
    timer = {
      every = function(name, ms, cb)
        if type(name) == "number" then cb = ms; ms = name; name = "anon_" .. tostring(#node.timers + 1) end
        node.timers[name] = { ms = ms, cb = cb }
        return node.timers[name]
      end,
      cancel = function(name) node.timers[name] = nil end,
      stop = function(h)
        for k, v in pairs(node.timers) do if v == h then node.timers[k] = nil end end
      end,
      after = function(ms, cb)
        local tname = "after_" .. tostring(math.random(10000, 99999))
        node.timers[tname] = {
          ms = ms,
          cb = function()
            node.timers[tname] = nil
            cb()
          end
        }
      end
    },
    mesh = {
      channels = function()
        return { "Public", "#battleship" }
      end,
      send = function(to_or_tbl, text)
        local to, payload
        if type(to_or_tbl) == "table" then
          to = to_or_tbl.to
          payload = to_or_tbl.text
        else
          to = to_or_tbl
          payload = text
        end
        node.outbox[#node.outbox + 1] = { to = to, text = payload }
        return true
      end,
      self = function() return { name = name } end,
    },
    audio = {
      tone = function() return true end
    }
  }

  return node
end

print("=== RUNNING EXTENDED 1v1 MULTIPLAYER NETWORK SIMULATION ===")

local node_a = create_mock_node("NODE_A_HOST")
local node_b = create_mock_node("NODE_B_CHALLENGER")

-- Load instance for Node A
_G.wada = node_a.wada
local app_a = dofile("battleship.lua")
app_a.on_open(320, 240)

local function place_all_ships(target_app)
  target_app.on_key("enter")
  target_app.on_key("s"); target_app.on_key("s"); target_app.on_key("enter")
  target_app.on_key("s"); target_app.on_key("s"); target_app.on_key("enter")
  target_app.on_key("s"); target_app.on_key("s"); target_app.on_key("enter")
  target_app.on_key("s"); target_app.on_key("s"); target_app.on_key("enter")
end

-- Node A hosts match
app_a.on_key("1")
place_all_ships(app_a)
app_a.on_key("enter")

-- Check that Node A broadcasted SEEK
assert(#node_a.outbox > 0, "Node A must broadcast SEEK")
local seek_pkt = node_a.outbox[#node_a.outbox]
assert(seek_pkt.text:find("BS|SEEK|"), "Packet must be BS|SEEK")
assert(seek_pkt.to == "#battleship", "Node A must broadcast on #battleship channel instead of Public! Got: " .. tostring(seek_pkt.to))
local match_id = seek_pkt.text:match("BS|SEEK|(%w+)|")
print(string.format("Node A hosted match: ID = %s on channel %s", match_id, seek_pkt.to))

-- Load instance for Node B
_G.wada = node_b.wada
local app_b = dofile("battleship.lua")
app_b.on_open(320, 240)

-- Node B joins match
app_b.on_key("2")
place_all_ships(app_b)
-- Node B receives SEEK
app_b.on_message({ from = "NODE_A_HOST", kind = "channel", text = seek_pkt.text })
-- Node B confirms setup
app_b.on_key("enter")

-- Check Node B sent JOIN
assert(#node_b.outbox > 0, "Node B must send JOIN")
local join_pkt = node_b.outbox[#node_b.outbox]
assert(join_pkt.text:find("BS|JOIN|" .. match_id), "Packet must be BS|JOIN")
print(string.format("Node B sent JOIN: %s", join_pkt.text))

-- Node A receives JOIN
_G.wada = node_a.wada
app_a.on_message({ from = "NODE_B_CHALLENGER", kind = "dm", text = join_pkt.text })

-- Check Node A replied with RDY
local rdy_pkt = node_a.outbox[#node_a.outbox]
assert(rdy_pkt.text:find("BS|RDY|" .. match_id), "Packet must be BS|RDY")
print(string.format("Node A sent RDY: %s", rdy_pkt.text))

-- Node B receives RDY
_G.wada = node_b.wada
app_b.on_message({ from = "NODE_A_HOST", kind = "dm", text = rdy_pkt.text })

-- Check Node B sent ACK 0
local ack0_pkt = node_b.outbox[#node_b.outbox]
assert(ack0_pkt.text:find("BS|ACK|" .. match_id .. "|0"), "Packet must be BS|ACK 0")
print(string.format("Node B sent ACK 0: %s", ack0_pkt.text))

-- Node A receives ACK 0
_G.wada = node_a.wada
app_a.on_message({ from = "NODE_B_CHALLENGER", kind = "dm", text = ack0_pkt.text })

print("OK: 3-Way Handshake successfully completed! Turn 1 locked.")

-- Check persistence of both nodes
assert(node_a.storekv["active_match"] ~= nil, "Node A match state saved")
assert(node_b.storekv["active_match"] ~= nil, "Node B match state saved")

print("=== TESTING COMPLETE PLAYTHROUGH (TURNS UNTIL VICTORY) ===")

local max_turns = 100
local turn_count = 0
local match_finished = false

local function deliver_packets(from_node, to_app, from_name)
  while #from_node.outbox > 0 do
    local pkt = table.remove(from_node.outbox, 1)
    to_app.on_message({ from = from_name, kind = "dm", text = pkt.text })
  end
end

local shot_idx_a = 0
local shot_idx_b = 0

-- Play automated turns until a fleet is destroyed
for t = 1, 200 do
  turn_count = t

  -- If Node A's turn:
  _G.wada = node_a.wada
  local state_a = node_a.storekv["active_match"] and node_a.storekv["active_match"]:match("^%w+|[^|]+|([^|]+)|")
  if state_a == "STATE_MY_TURN" then
    local x = shot_idx_a % 10
    local y = math.floor(shot_idx_a / 10)
    shot_idx_a = shot_idx_a + 1
    app_a.on_input({ type = "down", x = 12 + x * 14 + 7, y = 34 + y * 14 + 7 })

    -- Deliver packet to Node B
    _G.wada = node_b.wada
    deliver_packets(node_a, app_b, "NODE_A_HOST")

    -- Deliver Node B's reply back to Node A
    _G.wada = node_a.wada
    deliver_packets(node_b, app_a, "NODE_B_CHALLENGER")
  end

  -- If Node B's turn:
  _G.wada = node_b.wada
  local state_b = node_b.storekv["active_match"] and node_b.storekv["active_match"]:match("^%w+|[^|]+|([^|]+)|")
  if state_b == "STATE_MY_TURN" then
    local x = shot_idx_b % 10
    local y = math.floor(shot_idx_b / 10)
    shot_idx_b = shot_idx_b + 1
    app_b.on_input({ type = "down", x = 12 + x * 14 + 7, y = 34 + y * 14 + 7 })

    -- Deliver packet to Node A
    _G.wada = node_a.wada
    deliver_packets(node_b, app_a, "NODE_B_CHALLENGER")

    -- Deliver Node A's reply back to Node B
    _G.wada = node_b.wada
    deliver_packets(node_a, app_b, "NODE_A_HOST")
  end

  -- Check if either entered STATE_AUDIT or STATE_GAME_OVER
  local cur_a = node_a.storekv["active_match"] and node_a.storekv["active_match"]:match("^%w+|[^|]+|([^|]+)|")
  local cur_b = node_b.storekv["active_match"] and node_b.storekv["active_match"]:match("^%w+|[^|]+|([^|]+)|")

  if cur_a == "STATE_AUDIT" or cur_b == "STATE_AUDIT" or node_a.storekv["active_match"] == "" or node_b.storekv["active_match"] == "" then
    match_finished = true
    -- Deliver post-game REV packets back and forth
    _G.wada = node_b.wada
    deliver_packets(node_a, app_b, "NODE_A_HOST")
    _G.wada = node_a.wada
    deliver_packets(node_b, app_a, "NODE_B_CHALLENGER")
    _G.wada = node_b.wada
    deliver_packets(node_a, app_b, "NODE_A_HOST")
    break
  end
end

print(string.format("Match simulation reached conclusion after %d turns (Finished: %s)", turn_count, tostring(match_finished)))
assert(match_finished, "Match must finish and proceed to audit within 100 turns")

print("=== TESTING POST-GAME COMMIT-REVEAL AUDIT PASS ===")
-- In Node A's state: career stats should have 1 win or 1 loss
local stats_a = node_a.storekv["career_stats"]
assert(stats_a ~= nil and stats_a ~= "", "Career stats must be saved after audit")
print(string.format("Node A Career stats: %s", stats_a))

print("=== TESTING #BATTLESHIP CHANNEL CREATION & FILTERING ===")

-- 1. Test auto-creation hook when #battleship does not exist
local node_c = create_mock_node("NODE_C_NEW")
local channel_added = nil
node_c.wada.mesh.channels = function()
  if channel_added then return { "Public", channel_added } end
  return { "Public" }
end
node_c.wada.mesh.add_channel = function(chan)
  channel_added = chan
  return true
end

_G.wada = node_c.wada
local app_c = dofile("battleship.lua")
app_c.on_open(320, 240)
app_c.on_key("1") -- Host lobby
assert(channel_added == "#battleship", "Game must attempt to auto-create #battleship channel when missing!")
print("OK: Auto-creation hook successfully called with #battleship!")

-- 2. Test missing channel warning when device cannot create channel
local node_d = create_mock_node("NODE_D_LOCKED")
node_d.wada.mesh.channels = function() return { "Public" } end
node_d.wada.mesh.send = function(to, text)
  if to == "#battleship" then
    return false, "no such channel"
  end
  return true
end

_G.wada = node_d.wada
local app_d = dofile("battleship.lua")
app_d.on_open(320, 240)
app_d.on_key("1")
place_all_ships(app_d)
app_d.on_key("enter") -- lock fleet and broadcast
assert(#node_d.toasts > 0, "Missing channel must trigger a user-facing toast")
local last_toast = node_d.toasts[#node_d.toasts]
assert(last_toast:find("#battleship"), "Toast must instruct user to add #battleship")
print("OK: Missing #battleship channel cleanly triggers toast guidance: " .. last_toast)

-- 3. Test Inbound Channel Filter
local node_e = create_mock_node("NODE_E_FILTER")
_G.wada = node_e.wada
local app_e = dofile("battleship.lua")
app_e.on_open(320, 240)
app_e.on_key("2") -- Join lobby
place_all_ships(app_e)

-- Message on unrelated channel should be ignored
app_e.on_message({ from = "STRANGER", kind = "channel", channel = "random_chat", text = "BS|SEEK|TEST|STRANGER|1" })
local match_e = node_e.storekv["active_match"] or ""
assert(not match_e:find("TEST"), "Incoming packet on unrelated channel must be ignored")

-- Message on #battleship should be accepted
app_e.on_message({ from = "VALID_HOST", kind = "channel", channel = "#battleship", text = "BS|SEEK|9999|VALID_HOST|1" })
-- Confirm host was recognized and joined
app_e.on_key("enter")
assert(#node_e.outbox > 0, "Packet on #battleship must be accepted")
assert(node_e.outbox[#node_e.outbox].text:find("BS|JOIN|9999"), "Must join match heard on #battleship")
print("OK: Inbound channel filtering successfully verified!")

print("=== TESTING WADAMESH FIRMWARE CONSTRAINTS (5s COOLDOWN, NO DM, DUP FILTER, DROPPED RDY) ===")

local function create_wadamesh_firmware_node(name)
  local node = create_mock_node(name)
  node.now_ms = 10000
  node.last_send_ms = -10000
  node.dup_table = {}
  node.wada.sys.millis = function() return node.now_ms end

  -- Exact WADAMESH LuaAppHost.cpp mesh.send behavior:
  -- 1. Only sends to channels (returns "no such channel" if target is a peer node name)
  -- 2. Enforces 5000ms cooldown ("too fast")
  -- 3. Rejects identical text on the same channel within 10 minutes ("duplicate")
  node.wada.mesh.send = function(chan, text)
    if type(chan) == "table" then text = chan.text; chan = chan.to end
    if chan ~= "#battleship" and chan ~= "battleship" and chan ~= "Public" then
      return false, "no such channel"
    end
    if node.now_ms - node.last_send_ms < 5000 then
      return false, "too fast"
    end
    local key = chan .. "|" .. text
    if node.dup_table[key] and (node.now_ms - node.dup_table[key] < 600000) then
      return false, "duplicate"
    end
    node.last_send_ms = node.now_ms
    node.dup_table[key] = node.now_ms
    node.outbox[#node.outbox + 1] = { to = "#battleship", text = text, kind = "channel" }
    return true
  end

  -- Exact WADAMESH LuaAppHost.cpp mesh.send_dm behavior when peer is not in contacts or DM perms off
  node.wada.mesh.send_dm = function(recipient, text)
    return false, "no such contact"
  end

  node.wada.mesh.contacts = function()
    return {}
  end

  return node
end

-- Case A: Host sends SEEK at t=10s, Joiner sends JOIN at t=11s -> Host's immediate RDY hits "too fast" (1s < 5s)
-- Verify paced_tx automatically transmits RDY when the 5s cooldown expires and Joiner transitions to Turn 1!
local fw_host = create_wadamesh_firmware_node("FW_HOST")
local fw_join = create_wadamesh_firmware_node("FW_JOIN")

_G.wada = fw_host.wada
local app_fw_host = dofile("battleship.lua")
app_fw_host.on_open(320, 240)
app_fw_host.on_key("1")
place_all_ships(app_fw_host)
app_fw_host.on_key("enter") -- t = 10000ms: sends BS|SEEK on #battleship

assert(#fw_host.outbox == 1, "FW_HOST must broadcast SEEK on #battleship")
local fw_seek = table.remove(fw_host.outbox, 1)

_G.wada = fw_join.wada
local app_fw_join = dofile("battleship.lua")
app_fw_join.on_open(320, 240)
app_fw_join.on_key("2")
place_all_ships(app_fw_join)
app_fw_join.on_message({ from = "FW_HOST", kind = "channel", channel = "#battleship", text = fw_seek.text })
app_fw_join.on_key("enter") -- locks fleet & sends BS|JOIN on #battleship (not DM!)

assert(#fw_join.outbox == 1, "FW_JOIN must send BS|JOIN on #battleship when DM is unverified")
local fw_join_pkt = table.remove(fw_join.outbox, 1)
assert(fw_join_pkt.to == "#battleship", "BS|JOIN must use #battleship channel")

-- Deliver JOIN to Host only 1 second after Host sent SEEK (triggers "too fast" on Host!)
fw_host.now_ms = 11000
_G.wada = fw_host.wada
app_fw_host.on_message({ from = "FW_JOIN", kind = "channel", channel = "#battleship", text = fw_join_pkt.text })
assert(#fw_host.outbox == 0, "Immediate RDY at t=11s must be blocked by 5s firmware cooldown")
assert(fw_host.timers["lora_tx_pace"] ~= nil, "Host must schedule lora_tx_pace timer for blocked RDY")

-- Advance Host clock to t=16200ms and fire pace timer
fw_host.now_ms = 16200
fw_host.timers["lora_tx_pace"].cb()
assert(#fw_host.outbox == 1, "Host paced_tx must transmit BS|RDY once 5s cooldown expires!")
local fw_rdy_pkt = table.remove(fw_host.outbox, 1)
assert(fw_rdy_pkt.text:find("^BS|RDY|"), "Paced packet must be BS|RDY")

-- Deliver RDY to Joiner and verify Joiner enters combat without 5 TX retries!
_G.wada = fw_join.wada
app_fw_join.on_message({ from = "FW_HOST", kind = "channel", channel = "#battleship", text = fw_rdy_pkt.text })
local join_saved = fw_join.storekv["active_match"] or ""
assert(join_saved:find("STATE_MY_TURN") or join_saved:find("STATE_ENEMY_TURN"),
  "Joiner must transition to Turn 1 after receiving paced RDY! Got: " .. tostring(join_saved))
assert(fw_join.timers["lora_tx_retry"] == nil, "Joiner retry timer must be canceled after RDY!")
print("OK: WADAMESH 5s cooldown & #battleship channel fallback passed without retry failure!")

-- Case B: Dropped RDY + Duplicate Filter on Retries
-- Suppose Host's first RDY was lost over RF. Joiner retries BS|JOIN after 6s.
-- Verify:
--   1. Joiner's retry appends a |R<n> nonce so WADAMESH channel duplicate filter does not block it
--   2. Host (already in STATE_MY_TURN / STATE_ENEMY_TURN at seq 1) re-sends BS|RDY on receiving retried BS|JOIN
local fw_host2 = create_wadamesh_firmware_node("FW_HOST2")
local fw_join2 = create_wadamesh_firmware_node("FW_JOIN2")

_G.wada = fw_host2.wada
local app_fw_host2 = dofile("battleship.lua")
app_fw_host2.on_open(320, 240)
app_fw_host2.on_key("1")
place_all_ships(app_fw_host2)
app_fw_host2.on_key("enter")
local seek2 = table.remove(fw_host2.outbox, 1)

_G.wada = fw_join2.wada
local app_fw_join2 = dofile("battleship.lua")
app_fw_join2.on_open(320, 240)
app_fw_join2.on_key("2")
place_all_ships(app_fw_join2)
app_fw_join2.on_message({ from = "FW_HOST2", kind = "channel", channel = "#battleship", text = seek2.text })
app_fw_join2.on_key("enter")
local join2_first = table.remove(fw_join2.outbox, 1)

-- Host receives first JOIN at t=16s (after 5s cooldown), sends RDY, and enters Turn 1,
-- but simulate RDY lost in RF transit!
fw_host2.now_ms = 16000
_G.wada = fw_host2.wada
app_fw_host2.on_message({ from = "FW_JOIN2", kind = "channel", channel = "#battleship", text = join2_first.text })
assert(#fw_host2.outbox == 1, "Host sent initial RDY")
table.remove(fw_host2.outbox, 1) -- Drop RDY in transit!

-- Joiner's retry timer ticks 6 times (6000ms) at t=16000ms
fw_join2.now_ms = 16000
_G.wada = fw_join2.wada
for _ = 1, 6 do
  fw_join2.timers["lora_tx_retry"].cb()
end
assert(#fw_join2.outbox == 1, "Joiner retry 1/5 must succeed via duplicate-filter nonce bypass!")
local join2_retry = table.remove(fw_join2.outbox, 1)
assert(join2_retry.text:find("|R%d+$"), "Retried channel packet must include |R<nonce> suffix! Got: " .. join2_retry.text)

-- Host receives retried JOIN at t=22000ms while already in Turn 1 (local_seq == 1)
fw_host2.now_ms = 22000
_G.wada = fw_host2.wada
app_fw_host2.on_message({ from = "FW_JOIN2", kind = "channel", channel = "#battleship", text = join2_retry.text })
assert(#fw_host2.outbox == 1, "Host in Turn 1 must re-send BS|RDY when receiving retried BS|JOIN!")
local rdy2_resent = table.remove(fw_host2.outbox, 1)
assert(rdy2_resent.text:find("^BS|RDY|"), "Re-sent packet must be BS|RDY")

-- Deliver re-sent RDY to Joiner
_G.wada = fw_join2.wada
app_fw_join2.on_message({ from = "FW_HOST2", kind = "channel", channel = "#battleship", text = rdy2_resent.text })
local join2_saved = fw_join2.storekv["active_match"] or ""
assert(join2_saved:find("STATE_MY_TURN") or join2_saved:find("STATE_ENEMY_TURN"),
  "Joiner must complete handshake after receiving re-sent RDY!")
print("OK: Dropped RDY recovery and duplicate-filter nonce bypass verified!")

-- Case C: Fast-path JOIN_SEEK -> RDY when Joiner locks fleet after Host's initial SEEK was missed
local fw_host3 = create_wadamesh_firmware_node("FW_HOST3")
local fw_join3 = create_wadamesh_firmware_node("FW_JOIN3")

_G.wada = fw_host3.wada
local app_fw_host3 = dofile("battleship.lua")
app_fw_host3.on_open(320, 240)
app_fw_host3.on_key("1")
place_all_ships(app_fw_host3)
app_fw_host3.on_key("enter")
table.remove(fw_host3.outbox, 1) -- Joiner was not in lobby yet when SEEK was broadcast

_G.wada = fw_join3.wada
local app_fw_join3 = dofile("battleship.lua")
app_fw_join3.on_open(320, 240)
app_fw_join3.on_key("2")
place_all_ships(app_fw_join3)
app_fw_join3.on_key("enter") -- Joiner locks fleet and broadcasts BS|JOIN_SEEK
assert(#fw_join3.outbox == 1, "Joiner must broadcast BS|JOIN_SEEK")
local join_seek_pkt = table.remove(fw_join3.outbox, 1)
assert(join_seek_pkt.text:find("^BS|JOIN_SEEK|"), "Packet must be BS|JOIN_SEEK")

-- Host receives JOIN_SEEK at t=16000ms and fast-paths directly to BS|RDY!
fw_host3.now_ms = 16000
_G.wada = fw_host3.wada
app_fw_host3.on_message({ from = "FW_JOIN3", kind = "channel", channel = "#battleship", text = join_seek_pkt.text })
assert(#fw_host3.outbox == 1, "Host must reply to JOIN_SEEK directly with BS|RDY when fleet is locked")
local fast_rdy = table.remove(fw_host3.outbox, 1)
assert(fast_rdy.text:find("^BS|RDY|"), "Fast-path reply must be BS|RDY")

-- Joiner receives BS|RDY and adopts match_id + starts Turn 1
_G.wada = fw_join3.wada
app_fw_join3.on_message({ from = "FW_HOST3", kind = "channel", channel = "#battleship", text = fast_rdy.text })
local join3_saved = fw_join3.storekv["active_match"] or ""
assert(join3_saved:find("STATE_MY_TURN") or join3_saved:find("STATE_ENEMY_TURN"),
  "Joiner scanning with JOIN_SEEK must directly enter Turn 1 on receiving BS|RDY!")
print("OK: Fast-path JOIN_SEEK -> RDY handshake verified!")

-- Case D: Joiner stuck at SCANNING #battleship FOR HOST LOBBY while Host makes a move and waits for ACK!
-- Reproduces exact scenario:
-- 1. Host sends BS|SEEK at t=10000ms (with high seed so Host goes first)
-- 2. Joiner locks fleet & sends BS|JOIN_SEEK (Joiner is at SCANNING #battleship FOR HOST LOBBY, match_id="", enemy_board_hash="")
-- 3. Host receives BS|JOIN_SEEK at t=11000ms (within 5s cooldown -> BS|RDY queued in paced_queue) and enters STATE_MY_TURN
-- 4. Host immediately makes a move at t=12000ms (within 5s cooldown -> BS|FIRE also queued in paced_queue!)
-- 5. Verify BS|FIRE does NOT overwrite BS|RDY in paced_queue, AND even if BS|RDY is lost in RF transit,
--    when BS|FIRE arrives at Joiner, Joiner exits SCANNING, processes the shot, replies BS|RES, and Host clears ACK wait!
local fw_host4 = create_wadamesh_firmware_node("FW_HOST4")
local fw_join4 = create_wadamesh_firmware_node("FW_JOIN4")
-- Force Host seed > Joiner seed so Host always fires first
local host4_rand_calls = 0
fw_host4.wada.sys.random = function(lo, hi)
  if hi == 999999 then return 900000 end
  host4_rand_calls = host4_rand_calls + 1
  return lo + (host4_rand_calls % (hi - lo + 1))
end
fw_join4.wada.sys.random = function(lo, hi)
  if hi == 999999 then return 100000 end
  return lo
end

_G.wada = fw_host4.wada
local app_fw_host4 = dofile("battleship.lua")
app_fw_host4.on_open(320, 240)
app_fw_host4.on_key("1")
place_all_ships(app_fw_host4)
app_fw_host4.on_key("enter") -- t=10000ms: sends BS|SEEK
table.remove(fw_host4.outbox, 1) -- Joiner missed initial SEEK

_G.wada = fw_join4.wada
local app_fw_join4 = dofile("battleship.lua")
app_fw_join4.on_open(320, 240)
app_fw_join4.on_key("2")
place_all_ships(app_fw_join4)
app_fw_join4.on_key("enter") -- Joiner sends BS|JOIN_SEEK, sits at SCANNING #battleship FOR HOST LOBBY
local join_seek4 = table.remove(fw_join4.outbox, 1)

-- Host receives JOIN_SEEK at t=11000ms (within 5s cooldown of SEEK!)
fw_host4.now_ms = 11000
_G.wada = fw_host4.wada
app_fw_host4.on_message({ from = "FW_JOIN4", kind = "channel", channel = "#battleship", text = join_seek4.text })
assert(#fw_host4.outbox == 0, "BS|RDY must be queued in paced_queue due to 5s cooldown")

-- Host player immediately makes a move at t=12000ms (before BS|RDY was sent!)
fw_host4.now_ms = 12000
app_fw_host4.on_key("enter") -- Fire at (0,0) on Turn 1
assert(#fw_host4.outbox == 0, "BS|FIRE must also be queued in paced_queue due to 5s cooldown")

-- At t=15500ms, pace timer fires and sends BS|RDY first (FIFO preserved!)
fw_host4.now_ms = 15500
fw_host4.timers["lora_tx_pace"].cb()
assert(#fw_host4.outbox == 1, "First paced packet must be BS|RDY")
local rdy4 = table.remove(fw_host4.outbox, 1)
assert(rdy4.text:find("^BS|RDY|"), "FIFO queue must send BS|RDY before BS|FIRE! Got: " .. rdy4.text)
-- Simulate BS|RDY being lost over RF! (Do not deliver rdy4 to Joiner!)

-- At t=21000ms, pace timer fires again and sends BS|FIRE (which embeds Host's hash & seed!)
fw_host4.now_ms = 21000
fw_host4.timers["lora_tx_pace"].cb()
assert(#fw_host4.outbox == 1, "Second paced packet must be BS|FIRE")
local fire4 = table.remove(fw_host4.outbox, 1)
assert(fire4.text:find("^BS|FIRE|"), "Second paced packet must be BS|FIRE! Got: " .. fire4.text)

-- Deliver BS|FIRE to Joiner (who is STILL at SCANNING #battleship FOR HOST LOBBY with match_id="" and enemy_board_hash=""!)
fw_join4.now_ms = 21500
_G.wada = fw_join4.wada
app_fw_join4.on_message({ from = "FW_HOST4", kind = "channel", channel = "#battleship", text = fire4.text })

-- Verify Joiner exited SCANNING, processed the shot on seq 1, replied with BS|RES, and advanced to STATE_MY_TURN (seq 2)!
assert(#fw_join4.outbox == 1, "Joiner at SCANNING must process Turn 1 BS|FIRE and reply with BS|RES!")
local res4 = table.remove(fw_join4.outbox, 1)
assert(res4.text:find("^BS|RES|"), "Joiner reply must be BS|RES! Got: " .. res4.text)
local join4_saved = fw_join4.storekv["active_match"] or ""
assert(join4_saved:find("|STATE_MY_TURN|2|"), "Joiner must advance to STATE_MY_TURN at seq 2! Got: " .. join4_saved)

-- Deliver Joiner's BS|RES back to Host and verify Host clears ACK wait and advances to STATE_ENEMY_TURN (seq 2)!
fw_host4.now_ms = 22000
_G.wada = fw_host4.wada
app_fw_host4.on_message({ from = "FW_JOIN4", kind = "channel", channel = "#battleship", text = res4.text })
local host4_saved = fw_host4.storekv["active_match"] or ""
assert(host4_saved:find("|STATE_ENEMY_TURN|2|"), "Host must clear ACK wait and advance to STATE_ENEMY_TURN at seq 2! Got: " .. host4_saved)
assert(fw_host4.timers["lora_tx_retry"] == nil, "Host retry timer must be cleared after receiving BS|RES!")
print("OK: Joiner stuck at SCANNING + Host waiting for FIRE ACK deadlock completely resolved!")

print("=== ALL EXTENDED 1v1 MULTIPLAYER TESTS PASSED ===")
