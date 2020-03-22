#!/bin/bash
#set -vx
#==============================================================================================================================
# 説明    : 即席のおっさん放送情報取得用スクリプト
# 引数    : 無し
# 留意点  : 1, 実行時は./Ossan_liveinfo_get.sh & みたいな感じで実行してね。
#         : 2, 一応無限ループしてます。でも5秒感覚でスリープしてるからシステムに対する影響は微小なはず。
#         : 3, zenityコマンドを利用する都合上、Linux(ていうかUbuntu系?)環境じゃないと動かないorz
#==============================================================================================================================

#==============================================================================================================================
# 変数宣言
#==============================================================================================================================

#==== おっさん固有情報 ============================
# おっさんコミュID
mayohiga_id="1003067"

#==== 検索関連情報 ================================
# 検索値(qパラメータ)
q_param="ゲーム OR 描いてみた OR リスナーは外部記憶装置 OR 通知用"
# 検索項目(targetsパラメータ)
ta_param="tags"
# フィルター設定()
fil_param='[liveStatus][0]=onair&filters[communityId][0]='"$mayohiga_id"
# 表示項目(fieldsパラメータ)
fis_param="contentId,title,startTime,communityId"
#jsonデータ格納用変数
nicolive_jsondata=""

#==== 画面表示用文字列 ============================
# URL格納用変数
mayohiga_live_url=""
# 放送タイトル格納用変数
mayohiga_live_title=""
# 放送開始時間
mayohiga_live_starttime=""

#==== Zenityコマンド設定値(ウィンドウの大きさ) ====
Zen_height='300'
Zen_widh='600'

#==== フラグ変数 ==================================
# 放送開始確認フラグ(0:放送確認出来ず 1:放送確認)
mayohiga_live_status=0
# zenityコマンド起動フラグ(0:起動してない 1:起動した)
active_zenity=0

#==============================================================================================================================
# 各種関数
#==============================================================================================================================

#変数q_param値のURLエンコード実行関数
function qparam_urlenc () {

    # 変数q_paramに文字数が2文字以上入っていない場合は異常終了する
    if [ "${#q_param}" -le 1 ] ; then

        # エラーメッセージ
        echo '変数q_paramの値が何かおかしいっぽい'

        exit 1

    fi
    
    # 変数q_paramの値をurlエンコード化し、再度q_paramに値を格納
    q_param=$(perl -e '$ARGV[0]=~s/([^\w ])/"%".unpack("H2",$1)/eg;$ARGV[0]=~s/ /\+/g;print"$ARGV[0]\n"' "$q_param") || {

    # 上記処理が万が一失敗した場合、失敗処理メッセージを出力し、異常終了する
       echo "urlエンコードに失敗した・・・(perlのバージョン問題かも？)"

       exit 1

    }

}

# ニコニコAPI実行用関数
function nicolive_apirun () {

    # 変数nicolive_jsondataにapiから取得したデータを格納
    nicolive_jsondata=$(curl -A 'apiguide application' "https://api.search.nicovideo.jp/api/v2/live/contents/search?q=${q_param}&targets=${ta_param}&_sort=-viewCounter&_context=Ossan_liveinfo_get.sh&fields=${fis_param}&filters${fil_param}" --silent) || {

         # 処理失敗時はエラーメッセージ出力し、異常終了する
        echo 'curlコマンドで失敗したよ。APIサーバ側の障害？'

        exit 1

    }

}

# 取得したjsonデータの整形および整形データの変数代入処理
function jsondata_analysis () {

    # 変数nicolive_jsondataの値をechoし、jsonとして整形後、contentId行の第2フィールドの値が10以上ある場合は放送状態とみなす
    if [ $(echo "$nicolive_jsondata" | python -m json.tool | awk '/contentId/{print $2}' | wc -m) -gt 10 ] ; then

        # 放送が開始されている場合は、 変数nicolive_jsondataのtatle行,starttime行,contentId行を各変数に代入していく
        # contentId行を抽出し、放送URLに整形して変数mayohiga_live_urlに代入する
        mayohiga_live_url="https://nico.ms/$(echo "$nicolive_jsondata" | python -m json.tool | awk '/contentId/{print $2}' | sed -e 's/\"//g' -e 's/\,//')"
        
        # title行を抽出し、変数mayohiga_live_titleに格納する
        mayohiga_live_title=$(echo "$nicolive_jsondata" | python -m json.tool | awk '/title/{print $2}' | sed -e 's/\"//g' -e 's/\,//')

        # start_time行を抽出し、変数mayohiga_live_starttimeに代入する
        mayohiga_live_starttime=$(echo "$nicolive_jsondata" | python -m json.tool | awk '/startTime/{print $2}' | sed -e 's/\"//g' -e 's/\,//' -e 's/\-/\//g' -e 's/\+09\:00//'| tr T \ )

        # 変数mayohiga_live_status(放送開始確認フラグ)の値を1に変更する
        mayohiga_live_status=1
    fi

}

# zenityコマンド実行処理
function zenityinfo () {

    # zenityコマンドを実行する
    zenity --info --text="おっさんの放送が始まったよ！！\n 放送タイトル : $(echo -e ${mayohiga_live_title})\n 放送開始時間 : ${mayohiga_live_starttime}\n 放送URL : ${mayohiga_live_url}" --width="$Zen_widh" --height="$Zen_height" || {

        # 処理が失敗したらエラーメッセージを出力して異常終了する
        echo "zenityコマンドでコケたよ。ただここでコケたならおっさん放送してるはず！！"

        exit 1
    } 

    # 変数active_zenity(zenityコマンド起動フラグ)の値を1に変更
    active_zenity=1

}

#==============================================================================================================================
# メイン処理
#==============================================================================================================================

# 関数qparam_urlencを実行する
qparam_urlenc

# ここから無限ループ処理
while true ; do
    
    # 関数nicolive_apirunを実行する
    nicolive_apirun

    # 関数jsondata_analysisを実行する
    jsondata_analysis

    # フラグ変数mayohiga_live_statusの値により処理分岐
    if [ "$mayohiga_live_status" -eq 1 ] ; then

        # 放送が確認出来たら、関数zenityinfoを実行する
        zenityinfo

    fi

    # 変数active_zenityの値が0より大きい場合、無限ループから抜ける
    if [ "$active_zenity" -gt 0 ] ; then

        # ループから抜ける
        break

    fi

    # 無限ループは60秒感覚で実行
    sleep 60
done

#==============================================================================================================================
# 後処理
#==============================================================================================================================

# おっさんの放送を通知し終わったら、メッセージを標準出力し正常終了
echo "おっさんの放送を通知したので落ちるよ"

exit 0
