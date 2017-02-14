# hubot-mahjong
麻雀の点数計算や点数記録をするHubotスクリプトです。

## Installation
npmからインストールしてください。
```
npm install hubot-mahjong --save
```
external-scripts.jsonに以下の１行を追加してください。
```json:external-scripts.json
[
  "hubot-mahjong"
]
```
点数記録したデータを永続化したい場合は、[hubot-redis-brain](https://github.com/hubot-scripts/hubot-redis-brain) などを導入してください。

## Usage

メンションは必要ありません。モバイルでの使用を想定して、入力文字数を極力少なくしています。

### 点数計算
```
# 書式: mj <符> <翻>

mj 30 4

# => 30符4翻の点数は、7700(2000/3900)です。
```

### 点数記録
```
# 点数記録開始
# 書式: mj start <プレイヤー名> <プレイヤー名> <プレイヤー名> <プレイヤー名>

mj start foo bar baz qux

# => fooさん、barさん、bazさん、quxさんの点数記録を開始します。
#    ルール：
#    ・ウマ10-20 (mj rule uma 10-20)
#    ・25000点持ち (mj rule genten 25000)
#    ・30000点返し (mj rule kaeshi 30000)
#    ・点0.5 (mj rule ten 0.5)
#    飛び賞や役満祝儀は修正コマンド（mj mod）で修正してください:pray:
#    順位が変わらない場合は、点数に計上してから記録しても問題ないです。
#    それでは皆さんがんばってください！:tada:


# 点数記録
# 書式: mj reg <点数> <点数> <点数> <点数>

mj reg -1000 20000 25000 56000

# => 半荘1回目：
#    　fooさん -51、barさん -20、bazさん 5、quxさん 66
#    　（修正コマンド：mj mod #1 -51 -20 5 66）
#    トータル：
#    　fooさん -51、barさん -20、bazさん 5、quxさん 66


# 点数記録終了
# 書式: mj end

mj end

# => おつかれさまでした:clap:
#    半荘1回を0.5で計算：
#    　fooさん -2550、barさん -1000、bazさん 250、quxさん 3300
#    ---
#    トータル：
#    　fooさん -51、barさん -20、bazさん 5、quxさん 66
#    半荘：
#    　#1：fooさん -51、barさん -20、bazさん 5、quxさん 66
```

### 点数の再表示、点数の修正、ルールの調整
```
# 点数再表示
# 書式: mj show

mj show

# => 半荘1回目：
#    　fooさん -50、barさん -20、bazさん 5、quxさん 65
#    　（修正コマンド：mj mod #1 -51 -20 5 66）
#    トータル：
#    　fooさん -50、barさん -20、bazさん 5、quxさん 65
#    ルール：
#    ・ウマ10-20 (mj rule uma 10-20)
#    ・25000点持ち (mj rule genten 25000)
#    ・30000点返し (mj rule kaeshi 30000)
#    ・点0.5 (mj rule ten 0.5)


# 点数修正
# 書式: mj mod <半荘> <得点> <得点> <得点> <得点>

mj mod #1 -50 -20 5 65

# => 半荘1回目：
#    　fooさん -50、barさん -20、bazさん 5、quxさん 65
#    　（修正コマンド：mj mod #1 -51 -20 5 66）
#    トータル：
#    　fooさん -50、barさん -20、bazさん 5、quxさん 65


# ルールの調整
# 書式: mj rule (uma|genten|kaeshi|ten) <設定値>

mj uma 10-30

# => ルールを変更しました。
#    ・ウマ10-30
```

