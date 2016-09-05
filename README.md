# 単方向Payment Channelの簡易実装

## Configuration

### openassets.yml

UTXOの収集やブロードキャスト、トランザクションの取得に[openassets-ruby](https://github.com/haw-itn/openassets-ruby)を使ってるのでopenassets.yml.sampleを参考に設定ファイルを記述

### Railsの設定ファイル

* database.yml
* secrets.yml

## 使い方

```ruby
require 'openassets'

Bitcoin.network = :regtest

client_key  = Bitcoin::Key.from_base58('クライアントの秘密鍵')

client = PaymentChannel::Client.new(client_key: client_key)

# Channelのオープン
client.open

# サーバに公開鍵を要求
client.request_new_pubkey

# Channelのロックタイム（有効期間）ブロック高 or UNIXタイムスタンプで指定
locktime = 180

# 2. Opening Txを作成（署名済）
opening_tx, redeem_script, locked_addr = client.create_opening_tx(デポジットするSatoshiの量)

locked_vout = 0
opening_tx.out.each_with_index { |o, index|
  if o.parsed_script.get_address == locked_addr
    locked_vout = index
    break
  end
}

# 3. 払い戻し用のTxを作成（未署名）
refund_tx = client.create_refund_tx(opening_tx.hash, locked_vout, 払い戻しのsatoshiの量, locktime)

# 4. 払い戻し用Txをサーバに送って署名してもらう
half_signed_refund_tx = client.request_sign_refund_tx(refund_tx, redeem_script)

# 5. サーバの署名が正しいか検証
verify_refund_tx = client.verify_half_signed_refund_tx(opening_tx, half_signed_refund_tx, redeem_script)

# サーバの署名が正しい場合
if verify_refund_tx
  # 6. サーバにOpening Txを送付しブロードキャストしてもらう
  client.send_opening_tx(opening_tx)

  # 7. Commitment Txを作成＆署名しサーバに送付
  client.create_commitment_tx(opening_tx, locked_vout, クライアントのsatoshiの量, redeem_script)

  # create_commitment_txでクライアントのsatoshiの量を変えながらサーバとの決済を続ける

  # Channelのクローズ（サーバによって最新のCommitment Txがブロードキャストされる）
  client.close
end
```