# Description:
#   麻雀の点数表示や得点を記録します。
#
# Commands:
#   mj <符> <翻> - 符数、翻数に応じた点数を表示します。
#   mj start <名前>... - 得点の記録を開始します。参加メンバの名前をスペース区切りで入力します。
#   mj rule - ルールを表示します。
#   mj rule uma <ウマ(デフォルト:10-30)> - ウマを設定します。
#   mj rule genten <原点(デフォルト:25000)> - 原点を設定します。
#   mj rule kaeshi <返し(デフォルト:25000)> - 返し（オカ）を設定します。
#   mj rule ten <点(デフォルト:0.5)> - 点を設定します。
#   mj reg <点数>... - 点数を記録します。登録順でスペース区切りで入力します。
#   mj mod <半荘> <得失点差>... - 得失点差を修正します。登録順でスペース区切りで入力します。
#   mj show - 現在の合計得失点差、順位を表示します。
#   mj end - 得点の記録を終了し、点をかけた得失点差を表示します。

module.exports = (robot) ->

  POINT_MAP =
    "20": [undefined, "ツモアガリ(400/700)", "ツモアガリ(700/1300)", "ツモアガリ(1300/2600)"],
    "25": [undefined, "1600", "3200(800/1600)", "6400(1600/3200)"],
    "30": ["1000(300/500)", "2000(500/1000)", "3900(1000/2000)", "7700(2000/3900)"],
    "40": ["1300(400/700)", "2600(700/1300)", "5200(1300/2600)", "8000(2000/4000)"],
    "50": ["1600(400/800)", "3200(800/1600)", "6400(1600/3200)", "8000(2000/4000)"],
    "60": ["2000(500/1000)", "3900(1000/2000)", "7700(2000/3900)", "8000(2000/4000)"],
    "70": ["2300(600/1200)", "4500(1200/2300)", "8000(2000/4000)", "8000(2000/4000)"],
    "80": ["2600(700/1300)", "5200(1300/2600)", "8000(2000/4000)", "8000(2000/4000)"],
    "90": ["2900(800/1500)", "5800(1500/2900)", "8000(2000/4000)", "8000(2000/4000)"],
    "100": ["3200(800/1600)", "6400(1600/3200)", "8000(2000/4000)", "8000(2000/4000)"],
    "110": ["3600(900/1800)", "7100(1800/3600)", "8000(2000/4000)", "8000(2000/4000)"]

  POINT_LIST_MANGAN = [
    "8000(2000/4000)",
    "12000(3000/6000)",
    "12000(3000/6000)",
    "16000(4000/8000)",
    "16000(4000/8000)",
    "16000(4000/8000)",
    "24000(6000/12000)",
    "24000(6000/12000)"
  ]

  DEFAULT_RULES =
    "uma": "10-20",
    "genten": 25000,
    "kaeshi": 30000,
    "ten": 0.5

  BRAIN_KEY_GAMES = "HUBOT_MAHJONG_GAMES"
  BRAIN_KEY_PREFIX_GAME = "HUBOT_MAHJONG_GAME_"

  isGameStarted = false

  calcTotal = (game) ->
    total = {}
    total[member] = 0 for member in game.members
    for hanchan in game.hanchans
      for member, point of hanchan
        total[member] += point
    return total


  # 点数計算
  robot.hear /^mj\s+([0-9]{1,3})\s+([0-9]{1,2})$/i, (res) ->
    fu = res.match[1]
    han = Number(res.match[2])
    if han < 5
      point = if POINT_MAP[fu]? then POINT_MAP[fu][han - 1] else undefined
      if point?
        res.send "#{fu}符#{han}翻の点数は、#{point}です。"
      else
        res.send "#{fu}符#{han}翻の点数は、わかりません。"
    else if han < 13
      point = POINT_LIST_MANGAN[han - 5]
      res.send "#{fu}符#{han}翻の点数は、#{point}です。"
    else
      point = "32000(8000/16000)"
      res.send "#{fu}符#{han}翻の点数は、#{point}です。"


  # 記録開始
  robot.hear /^mj\s+start((?:\s+[^ ]+){4})$/i, (res) ->
    # 入力値
    members = res.match[1].split(/\s/)
    members.shift()

    # チェック
    if isGameStarted
      return res.send "エラー：前のゲームが終了していません。"
    else
      isGameStarted = true

    # ゲーム登録
    games = robot.brain.get(BRAIN_KEY_GAMES) or []
    gameKey = Number(new Date())
    games.push gameKey
    robot.brain.set(BRAIN_KEY_GAMES, games)

    game = {}
    game["members"] = members
    game["rules"] = DEFAULT_RULES
    game["hanchans"] = []
    game["start_date"] = new Date()
    robot.brain.set("#{BRAIN_KEY_PREFIX_GAME}#{gameKey}", game)

    # レスポンス
    membersStr = ("#{i}さん" for i in members).join("、")
    uma = game.rules.uma
    genten = game.rules.genten
    kaeshi = game.rules.kaeshi
    ten = game.rules.ten
    messages = []
    messages.push "#{membersStr}の点数記録を開始します。"
    messages.push "ルール："
    messages.push "・ウマ#{uma} (mj rule uma #{uma})"
    messages.push "・#{genten}点持ち (mj rule genten #{genten})"
    messages.push "・#{kaeshi}点返し (mj rule kaeshi #{kaeshi})"
    messages.push "・点#{ten} (mj rule ten #{ten})"
    messages.push "飛び賞や役満祝儀は修正コマンド（mj mod）で修正してください:pray:"
    messages.push "順位が変わらない場合は、点数に計上してから記録しても問題ないです。"
    messages.push "それでは皆さんがんばってください！:tada:"
    res.send messages.join("\n")


  # 点数記録
  robot.hear /^mj\s+reg((?:\s+[^ ]+){4})$/i, (res) ->
    # 入力値
    pointsInput = res.match[1].split(/\s/)
    pointsInput.shift()
    points = (Number(i) for i in pointsInput)

    # チェック
    if not isGameStarted
      return res.send "エラー：ゲームが開始していません。"

    games = robot.brain.get(BRAIN_KEY_GAMES)
    game = robot.brain.get("#{BRAIN_KEY_PREFIX_GAME}#{games[games.length - 1]}")

    sum = 0
    sum += i for i in points
    if sum != game.rules.genten * game.members.length
      return res.send "エラー：点数の合計に誤りがあるようです。合計：#{sum}"

    if points.length != game.members.length
      return res.send "エラー：メンバの数と一致しません。メンバ数：#{game.members.length}、入力数：#{points.length}"

    # 点数記録
    hanchan = {}
    hanchan[member] = (points[i] - game.rules.kaeshi) / 1000 for member, i in game.members
    # console.log hanchan
    uma = game.rules.uma.split("-")
    uma = [Number(uma[1]), Number(uma[0]), - Number(uma[0]), - Number(uma[1])]
    # console.log uma
    sorted = []
    for k, v of hanchan
      length = sorted.length
      for member, i in sorted
        if v > hanchan[member]
          bigger = sorted.slice(0, i)
          bigger.push k
          # console.log "bigger: #{bigger}"
          lower = sorted.slice(i)
          # console.log "lower: #{lower}"
          sorted = bigger.concat lower
          break
      sorted.push k if length == sorted.length
      # console.log sorted
    for member, i in sorted
      # console.log "#{member}: #{hanchan[member]}"
      hanchan[member] += uma[i]
      if i == 0
        hanchan[member] += (game.rules.kaeshi - game.rules.genten) * game.members.length / 1000
      # console.log "#{member}: #{hanchan[member]}"
    game.hanchans.push hanchan

    # トータル計算
    game.total = calcTotal(game)

    robot.brain.set("#{BRAIN_KEY_PREFIX_GAME}#{games[games.length - 1]}", game)

    # レスポンス
    pointStr = ("#{k}さん #{v}" for k, v of hanchan).join("、")
    modStr = (v for k, v of hanchan).join(" ")
    totalStr = ("#{k}さん #{v}" for k, v of game.total).join("、")
    messages = []
    messages.push "半荘#{game.hanchans.length}回目："
    messages.push "　#{pointStr}"
    messages.push "　（修正コマンド：mj mod ##{game.hanchans.length} #{modStr}）"
    messages.push "トータル："
    messages.push "　#{totalStr}"
    res.send messages.join("\n")


  # 点数修正
  robot.hear /^mj\s+mod\s+#([0-9]+)((?:\s+[^ ]+){4})$/i, (res) ->
    # 入力値
    gameNoInput = res.match[1]
    gameNo = Number(gameNoInput) - 1
    pointsInput = res.match[2].split(/\s/)
    pointsInput.shift()
    points = (Number(i) for i in pointsInput)

    # チェック
    if not isGameStarted
      return res.send "エラー：ゲームが開始していません。"

    games = robot.brain.get(BRAIN_KEY_GAMES)
    game = robot.brain.get("#{BRAIN_KEY_PREFIX_GAME}#{games[games.length - 1]}")

    sum = 0
    sum += i for i in points
    if sum != 0
      return res.send "エラー：点数の合計に誤りがあるようです。合計：#{sum}"

    if points.length != game.members.length
      return res.send "エラー：メンバの数と一致しません。メンバ数：#{game.members.length}、入力数：#{points.length}"

    if not game.hanchans[gameNo]?
      return res.send "エラー：半荘が見つかりません。入力した半荘番号：##{gameNoInput}"

    # 点数修正
    hanchan = game.hanchans[gameNo]
    hanchan[member] = points[i] for member, i in game.members

    # トータル計算
    game.total = calcTotal(game)

    robot.brain.set("#{BRAIN_KEY_PREFIX_GAME}#{games[games.length - 1]}", game)

    # レスポンス
    pointStr = ("#{k}さん #{v}" for k, v of hanchan).join("、")
    modStr = (v for k, v of hanchan).join(" ")
    totalStr = ("#{k}さん #{v}" for k, v of game.total).join("、")
    messages = []
    messages.push "半荘#{game.hanchans.length}回目："
    messages.push "　#{pointStr}"
    messages.push "　（修正コマンド：mj mod ##{game.hanchans.length} #{modStr}）"
    messages.push "トータル："
    messages.push "　#{totalStr}"
    res.send messages.join("\n")


  # ルール変更（ウマ）
  robot.hear /^mj\s+rule\s+uma\s+([0-9]{1,2}-[0-9]{1,2})$/i, (res) ->
    # 入力値
    uma = res.match[1]

    # チェック
    if not isGameStarted
      return res.send "エラー：ゲームが開始していません。"

    ary = uma.split("-")
    if ary[0] > ary[1]
      return res.send "エラー：順位点は小さい方から並べてください。入力：#{uma}"

    games = robot.brain.get(BRAIN_KEY_GAMES)
    game = robot.brain.get("#{BRAIN_KEY_PREFIX_GAME}#{games[games.length - 1]}")

    # ルール保存
    game.rules.uma = uma
    robot.brain.set("#{BRAIN_KEY_PREFIX_GAME}#{games[games.length - 1]}", game)

    # レスポンス
    messages = []
    messages.push "ルールを変更しました。"
    messages.push "・ウマ#{uma}"
    res.send messages.join("\n")


  # ルール変更（原点）
  robot.hear /^mj\s+rule\s+genten\s+([0-9]{5})$/i, (res) ->
    # 入力値
    genten = Number(res.match[1])

    # チェック
    if not isGameStarted
      return res.send "エラー：ゲームが開始していません。"

    games = robot.brain.get(BRAIN_KEY_GAMES)
    game = robot.brain.get("#{BRAIN_KEY_PREFIX_GAME}#{games[games.length - 1]}")

    if genten > game.rules.kaeshi
      return res.send "エラー：返しよりも小さな値を設定してください。返し：#{game.rules.kaeshi}"

    # ルール保存
    game.rules.genten = genten
    robot.brain.set("#{BRAIN_KEY_PREFIX_GAME}#{games[games.length - 1]}", game)

    # レスポンス
    messages = []
    messages.push "ルールを変更しました。"
    messages.push "・#{genten}点持ち"
    res.send messages.join("\n")


  # ルール変更（返し）
  robot.hear /^mj\s+rule\s+kaeshi\s+([0-9]{5})$/i, (res) ->
    # 入力値
    kaeshi = Number(res.match[1])

    # チェック
    if not isGameStarted
      return res.send "エラー：ゲームが開始していません。"

    games = robot.brain.get(BRAIN_KEY_GAMES)
    game = robot.brain.get("#{BRAIN_KEY_PREFIX_GAME}#{games[games.length - 1]}")

    if kaeshi < game.rules.genten
      return res.send "エラー：原点よりも大きな値を設定してください。原点：#{game.rules.genten}"

    # ルール保存
    game.rules.kaeshi = kaeshi
    robot.brain.set("#{BRAIN_KEY_PREFIX_GAME}#{games[games.length - 1]}", game)

    # レスポンス
    messages = []
    messages.push "ルールを変更しました。"
    messages.push "・#{kaeshi}点返し"
    res.send messages.join("\n")


  # ルール変更（点）
  robot.hear /^mj\s+rule\s+ten\s+([0-9\.]+)$/i, (res) ->
    # 入力値
    ten = Number(res.match[1])

    # チェック
    if not isGameStarted
      return res.send "エラー：ゲームが開始していません。"

    if isNaN(ten)
      return res.send "エラー：数字を入力してください。"

    games = robot.brain.get(BRAIN_KEY_GAMES)
    game = robot.brain.get("#{BRAIN_KEY_PREFIX_GAME}#{games[games.length - 1]}")

    # ルール保存
    game.rules.ten = ten
    robot.brain.set("#{BRAIN_KEY_PREFIX_GAME}#{games[games.length - 1]}", game)

    # レスポンス
    messages = []
    messages.push "ルールを変更しました。"
    messages.push "・点#{ten}"
    res.send messages.join("\n")


  # 点数表示
  robot.hear /^mj\s+show$/i, (res) ->
    # チェック
    if not isGameStarted
      return res.send "エラー：ゲームが開始していません。"

    games = robot.brain.get(BRAIN_KEY_GAMES)
    game = robot.brain.get("#{BRAIN_KEY_PREFIX_GAME}#{games[games.length - 1]}")

    # レスポンス
    totalStr = ("#{k}さん #{v}" for k, v of game.total).join("、")
    uma = game.rules.uma
    genten = game.rules.genten
    kaeshi = game.rules.kaeshi
    ten = game.rules.ten
    messages = []
    messages.push "トータル："
    messages.push "　#{totalStr}"
    messages.push "半荘："
    for hanchan, i in game.hanchans
      pointStr = ("#{k}さん #{v}" for k, v of hanchan).join("、")
      messages.push "　##{i + 1}：#{pointStr}"
    messages.push "ルール："
    messages.push "・ウマ#{uma} (mj rule uma #{uma})"
    messages.push "・#{genten}点持ち (mj rule genten #{genten})"
    messages.push "・#{kaeshi}点返し (mj rule kaeshi #{kaeshi})"
    messages.push "・点#{ten} (mj rule ten #{ten})"
    res.send messages.join("\n")


  # 記録終了
  robot.hear /^mj\s+end$/i, (res) ->
    # チェック
    if not isGameStarted
      return res.send "エラー：ゲームが開始していません。"
    else
      isGameStarted = false

    # トータル計算
    games = robot.brain.get(BRAIN_KEY_GAMES)
    game = robot.brain.get("#{BRAIN_KEY_PREFIX_GAME}#{games[games.length - 1]}")
    game.total = calcTotal(game)
    game["end_date"] = new Date()
    robot.brain.set("#{BRAIN_KEY_PREFIX_GAME}#{games[games.length - 1]}", game)

    resultStr = ("#{k}さん #{v * game.rules.ten * 100}" for k, v of game.total).join("、")
    totalStr = ("#{k}さん #{v}" for k, v of game.total).join("、")
    messages = []
    messages.push "おつかれさまでした。"
    messages.push "半荘#{game.hanchans.length}回を#{game.rules.ten}で計算："
    messages.push "　#{resultStr}"
    messages.push "---"
    messages.push "トータル："
    messages.push "　#{totalStr}"
    messages.push "半荘："
    for hanchan, i in game.hanchans
      pointStr = ("#{k}さん #{v}" for k, v of hanchan).join("、")
      messages.push "　##{i + 1}：#{pointStr}"
    res.send messages.join("\n")

