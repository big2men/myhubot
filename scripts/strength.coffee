# Description:
#   hubot に誰がどんな強み（資質）を持っているか記憶させる／聞く
#
# Commands:
#   hubot <user>の強みは何？
#   hubot <user>のN番の強みは何？
#   hubot <user>の強みはxxです。
#   hubot <user>の強みはxxとyy、zzです。
#   hubot <user>のN番の強みはxxです。
#   hubot 皆の強みを教えて！

CSON = require 'cson'

class StrengthList
  @strengths = CSON.parseFileSync 'config/strengths.cson'

  # Return List or Detail of specified strength name
  #
  # @param string name name or title of strength
  @get: (name) ->
    unless name?
      return @strengths

    if @strengths[name]?
      return @strengths[name]
    else
      for key, strength of @strengths
        if name == strength.title
          return strength
    return false

  @getTitle: (name) ->
    strength = @get name

    return strength.title if strength.title?

module.exports = (robot) ->

  respond_user_strength = (msg) ->
    [user_name, strength_label, rank_index] = msg.data
    strength_name = robot.brain.data.strength[user_name][rank_index]
    strength_title = StrengthList.getTitle(strength_name)

    if strength_title?
      msg.send "やだなぁ、#{user_name}の#{rank_index+1}番の#{strength_label}は *#{strength_title}* じゃないですか"
    else
      msg.send "登録されていません！"

  save_user_strength = (msg) ->
    [full_text, user_name, strength_label, strength_text, rank_index] = msg.data
    strength_arr = strength_text.split /\s*[,、]\s*/
    ranking = []

    for value, i in strength_arr
      strength = StrengthList.get value
      if strength != false
        ranking.push strength

    if ranking.length > 0
      if ranking.length == 1
        strength = ranking[0]
        robot.brain.data.strength[user_name][0] = strength.title
        msg.send "#{user_name}の#{strength_label}は#{strength.title}ですね。"
      else
        for strength, i in ranking
          robot.brain.data.strength[user_name][i] = strength.title
          msg.send "#{user_name}の#{i+1}番目の#{strength_label}は#{strength.title}ですね。"
    else
      msg.send "該当する#{strength_label}が見当たりません。"

  robot.respond /@?([a-z0-9]+)\s*の(強み|資質)は(何(だっけ)?)?？/i, (msg) ->
    msg.data = [
      msg.match[1],
      msg.match[2],
      0
    ]
    respond_user_strength msg

  robot.respond /@?([a-z0-9]+)\s*の(\d)番目?の(強み|資質)は(何(だっけ)?)?？/i, (msg) ->
    msg.data = [
      msg.match[1],
      msg.match[3],
      msg.match[2]-1
    ]
    respond_user_strength msg


  robot.respond /@?([a-z0-9]+)\s*の(強み|資質)は(?!何)(.+?)(です。?)?$/i, (msg) ->
    msg.data = msg.match
    msg.data.push 0
    save_user_strength msg
