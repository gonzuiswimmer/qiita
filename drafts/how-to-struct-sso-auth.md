---
title: SSO認証に対応するまでにやったこと
tags:
  - ""
private: false
updated_at: ""
id: null
organization_url_name: null
slide: false
ignorePublish: false
---

## はじめに

この記事は前回記事（外部認証方式）の続きです。<br>
「toB向けに展開しているWebアプリにSSO機能を実装」するという、実際の開発体験をまとめました。

## 対象読者

- 認証・認可について理解を深めたいエンジニア
- SSO機能の実装を検討している人
- 要件定義を担当する中級エンジニア

## 前回までのまとめ

SSOとはSingle Sign On(シングルサインオン)の略であり、一度の認証で複数のアプリやサービスを利用できるようにする仕組みです。<br>
一般的には、Identity Provider（IdP）に認証を委譲し、各サービス側はその認証結果を受け取ってログインを成立させます。

## 実際にやったこと・導入までの流れ

- 1. SSOについての調査
- 2. SAMLについての理解
- 3. ローカル環境の構築。IdPサーバーの構築
- 4. SAML対応パッケージの導入と機能実装
- 5. 社内情報システム部との調整、SP登録
- 6. ドキュメントの整備

### 1. SSOについての調査、認証と認可の違いの把握

#### 用語理解と機能イメージ

SSO機能の開発が持ち上がった当初は、私自身もSSOに対してあまり詳しくなかったため、「どのような技術でどのように実装すればよさそうか」といった実装イメージをつけるために、諸々キャッチアップを行いました。<br>
その中で得た知見が前回記事の内容です。

#### 社内の別部署での導入済み事例のヒアリング

すでに導入済みの別サービスが社内にあったため、その部署が主催する共有会に参加させていただきました。<br>
ヒアリングはとても有益なものでしたが、公開されている企業の設定マニュアルなどもとても参考になりました。<br>
例えば国内シェアトップのクラウドセキュリティ（と書いてある）HENNGE Oneでは、SlackやDropbox、Chatwork、SmartHRなど464以上のサービスに対応しており、ヘルプセンターにはサービスプロバイダ（SP）の登録マニュアルもあるので、本記事のような個人がまとめた手順書よりも分かりやすいです。<br>
また、連携先のWebアプリ（例えば上記のChatwork）側にもIdP設定マニュアルが公開されているので、自社アプリで用意すべき設定画面や項目、マニュアルなどを容易にイメージできました。

#### IdPの代表例

- Okta
- Microsoft Entra ID
- HENNGE ONE
  など

#### Webアプリ

- Salesforce
- Kintone
- Google Workspace
- Dropbox
  など

### 2. SAMLについての理解

調査を行う中で、SSOにはどうやらSAML2.0という認証規格が使用されており、この規格に合わせないといけないことが分かりました。<br>
詳細はより詳しい参考記事があるので参照いただきたいですが、機能実装をするうえで最低限理解すべきことについて重点的に解説したいと思います

- SAML2.0とは？
- SAML認証の仕組み（フロー）
- XML署名のどこに認証データが含まれるか

#### SAML2.0とは？

SAMLはXMLベースの認証プロトコルで、IdpがSP向けにデジタル署名入りのXMLドキュメントを発行することで認証を行います。<br>
もともとは2002年に生まれた企画ですが、2005年にSAML2.0にバージョンアップされ、旧バージョンはすでに使用されていないため、現在ではSAMLといえばSAML2.0のことを指します

#### SAML2.0 の認証の仕組み（フロー）

```mermaid
<!-- 設計図を入れる。作成済みなため、転記する！！ -->
```

#### XML署名のどこに認証データが含まれるか

XML証明書（SAMLアサーション）の中身には、Idpの情報、認証後に遷移するSpのURL、SAML証明書など重要な情報が多く入っていますが、実装上カスタムする必要があるのは`user_name`です。<br>

<details>
  <summary>クリックしてSAMLアサーションの例を確認する</summary>

<!-- SAML証明書を実際に確認して、マスクしたうえで転記する！！ -->

```
<samlp:Response xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol"
                ID="_e000000000000000000000000000000"
                Version="2.0"
                IssueInstant="2023-10-13T08:15:17.327Z"
                Destination="https://utas.adm.u-tokyo.ac.jp/Shibboleth.sso/SAML2/POST"
                InResponseTo="_b1111111111111111111111111111111"
                >
    <Issuer xmlns="urn:oasis:names:tc:SAML:2.0:assertion">https://sts.windows.net/AzureAD上の大学テナントID/</Issuer>
    <samlp:Status>
        <samlp:StatusCode Value="urn:oasis:names:tc:SAML:2.0:status:Success" />
    </samlp:Status>
    <Assertion xmlns="urn:oasis:names:tc:SAML:2.0:assertion"
               ID="_c12312312312312312312312312312312312"
               IssueInstant="2023-10-13T08:15:17.323Z"
               Version="2.0"
               >
        <Issuer>https://sts.windows.net/AzureAD上の大学テナントID/</Issuer>
        <Signature xmlns="http://www.w3.org/2000/09/xmldsig#">
            <SignedInfo>
                <CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#" />
                <SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256" />
                <Reference URI="#_c12312312312312312312312312312312312">
                    <Transforms>
                        <Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />
                        <Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#" />
                    </Transforms>
                    <DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256" />
                    <DigestValue>123123123123123123123123123123123123=のような値</DigestValue>
                </Reference>
            </SignedInfo>
            <SignatureValue>11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111==みたいな感じの値</SignatureValue>
            <KeyInfo>
                <X509Data>
                    <X509Certificate>111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111みたいな感じの値</X509Certificate>
                </X509Data>
            </KeyInfo>
        </Signature>
        <Subject>
            <NameID Format="urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress">大学での自分のID@大学のメール</NameID>
            <SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer">
                <SubjectConfirmationData InResponseTo="_b1111111111111111111111111111111"
                                         NotOnOrAfter="2023-10-13T09:15:17.244Z"
                                         Recipient="https://utas.adm.u-tokyo.ac.jp/Shibboleth.sso/SAML2/POST"
                                         />
            </SubjectConfirmation>
        </Subject>
        <Conditions NotBefore="2023-10-13T08:10:17.244Z"
                    NotOnOrAfter="2023-10-13T09:15:17.244Z"
                    >
            <AudienceRestriction>
                <Audience>https://utas.adm.u-tokyo.ac.jp/shibboleth-sp</Audience>
            </AudienceRestriction>
        </Conditions>
        <AttributeStatement>
            <Attribute Name="http://schemas.microsoft.com/identity/claims/tenantid">
                <AttributeValue>AzureAD上の大学テナントID</AttributeValue>
            </Attribute>
            <Attribute Name="http://schemas.microsoft.com/identity/claims/objectidentifier">
                <AttributeValue>また別のID</AttributeValue>
            </Attribute>
            <Attribute Name="http://schemas.microsoft.com/identity/claims/identityprovider">
                <AttributeValue>https://sts.windows.net/AzureAD上の大学テナントID/</AttributeValue>
            </Attribute>
            <Attribute Name="http://schemas.microsoft.com/claims/authnmethodsreferences">
                <AttributeValue>urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport</AttributeValue>
                <AttributeValue>http://schemas.microsoft.com/claims/multipleauthn</AttributeValue>
            </Attribute>
            <Attribute Name="urn:oid:0.9.2342.19200300.100.1.1">
                <AttributeValue>大学での自分のID</AttributeValue>
            </Attribute>
        </AttributeStatement>
        <AuthnStatement AuthnInstant="2023-05-11T03:14:23.379Z"
                        SessionIndex="_c12312312312312312312312312312312312"
                        >
            <AuthnContext>
                <AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport</AuthnContextClassRef>
            </AuthnContext>
        </AuthnStatement>
    </Assertion>
</samlp:Response>
```

</details>

<br>
<br>
cf. 参考記事：
[身近なSAML認証の中身を見てみた](https://zenn.dev/kobababa/articles/99647784322610)

### 3. ローカル環境の構築。IdPサーバーの構築

機能実装するために必須となるIdPは、OSSのKeycloakを使用しました。
選定理由としてはドキュメントの豊富さとDockerコンテナで環境を迅速に構築できたからです。ローカル環境のPoC段階で社内のIdpであるMicrosoft Entra IDを利用するのはオーバースペック（申請が許可されない可能性が高く、https通信の対応に手間がかかる、など負担増）であり、それ用に別途IdPを契約するのも時間とコストがかかるため除外しました。<br>
また、ローカル環境では`docker compose`による複数コンテナ運用しており、既存リソースとの統合も簡単だったため、Dockerによる環境構築とコンテナ運用がベストでした。

### 4. SAML対応パッケージの導入と機能実装

APIサーバーにはLaravelを使用しており、SAML2.0に対応している必要があることから、[`24slides/laravel-saml2`](https://github.com/scaler-tech/laravel-saml2)を入れて対応しました。<br>
最も重要なことは`AppServiceProvider`に`Slides\Saml2\SignedIn`リスナーイベントを記載し、サインインイベントが起きたときにXML証明書から取得したユーザーを、既存WEBアプリ上のユーザーと紐づけてログイン処理を統合することです。<br>

:::note warning
ここで、SAML2.0の認証の仕組みとXML証明書の概要が分かっていないと手こずります。<br>
Idpによってはユーザーデータをメールアドレス以外に設定することもあるようなので、その場合はこの`$userData`を取得する処理を修正するか、Idp側でメールアドレスを返すように統一しないと紐づけが失敗することがあります。
:::

```
Event::listen(\Slides\Saml2\Events\SignedIn::class, function (\Slides\Saml2\Events\SignedIn $event) {
    $messageId = $event->getAuth()->getLastMessageId();

    // your own code preventing reuse of a $messageId to stop replay attacks
    $samlUser = $event->getSaml2User();

    $userData = [
        'id' => $samlUser->getUserId(),
        'attributes' => $samlUser->getAttributes(),
        'assertion' => $samlUser->getRawSamlAssertion()
    ];

    $user = // find user by ID or attribute

    // Login a user.
    Auth::login($user);
});
```

cf. 参考記事
[LaravelアプリケーションにSAML認証方式のシングルサインオンログインを実装する(ライブラリ編)](https://qiita.com/shkfn/items/8ebea0d0dd605b955221)

### 5. 社内情報システム部との調整、SP登録

SSO機能を社内で利用したい場合、社内情報システム部等の部署に申請をして、SP登録をしてもらう必要があります。

登録の仕方は企業で利用しているIdPによって異なりますが、
動作確認用に開発環境から本番環境まで全てで利用申請をしましたが、インフラ設計が微妙に異なるせいで何度も申請が必要になりました。
また、申請から受理・作業完了までは日数がかかるため、「社内調整」が必要でした。

### 6. 利用者向けのSSO設定画面の作成

Idpの設定はユーザーが各自で設定するため、ユーザーが所属する企業が使用可能なIdpの情報と、発行される認証キーが確認可能なダッシュボードを構築する必要があります。<br>

#### 各ユーザーに追加で紐づける情報

- SSOが利用可能かどうかを管理するフラグ
  →ユーザー単位でSSOの利用可否を制御するため。
- SSOに使用するメールアドレス（必ず一意である必要がある）
  →Idpで利用しているメールアドレス。通常登録されているアドレスはIdpに登録されていない可能性もあるため、紐づけ用として追加

#### ユーザー（およびユーザーが所属するグループ）で利用するIdpの情報

- 設定名（任意）
- 識別子（エンティティID。）
- 応答URL（ACS_URL。認証トークンを受け取るURLであり、公開キーが取得できる）
- サインオンURL
- 発行される認証キー（Base64のSAML証明書。設定を保存すると、Sp側で認証キーが発行され、その認証キーをIdp側で登録する必要がある）

### 7.ドキュメントの整備

上記の申請手順はWebアプリ・サービスを利用するお客様企業側でも実施いただく必要があるため、適宜画面キャプチャを取って作業手順書を作成しました。<br>
他社様のドキュメントを参考にしつつ、自社サービス向けに必要な設定内容等を追記し、仕上げていきます。<br>
参考資料が豊富なので時間はかかりませんが、用語については統一感を持たせる必要があるのと、`Sp-Initiated`か`Idp-Initiated`化によってユーザーストーリーが変わってくるので、その点に配慮して記載しました。

<details>
<summary>Sp-InitiatedとIdp-Initiatedの違いについて</summary>
両社の違いは、**どちらからのアクセスを前提とするか**です。

#### Sp-Initiated

`Sp-Initiated`は、サービスプロバイダ（＝SSOを導入するクラウドサービス）側からSAMLリクエストを発行します。<br>
その後、連携しているIdpへリダイレクトし、認証フローを経由後、登録済みの応答URL（SSOを導入するクラウドサービス側のログイン画面）へアクセスします。

#### Idp-Initiated

`Idp-Initiated`は、Idプロバイダ（Microsoft Entra IDなど）側からサービスプロバイダへSAMLリクエストを発行します<br>
まずIdpでログインし、任意の画面から連携しているクラウドサービスおよびそのURLをクリックすることで、クラウドサービスのログイン画面へアクセスします。

</details>
<br>
<br>

cf. 参考記事
[salesforceのドキュメント](https://help.salesforce.com/s/articleView?id=xcloud.sso_about.htm&type=5)
[cybozu.comのSAMLドキュメント](https://cybozu.dev/ja/common/tips/authentication/saml-authentication-with-other-services/)

## まとめ

実際に導入しようとすると、調査、社内調整、利用者向けの設定画面とドキュメントの整備まで含めて設計する必要があり、思いのほか大変だ、という点が伝わりますと幸いです。
特に今回の「SSO機能」のような外部サービスを利用するケースでは、事前調査～ドキュメントの整備までイメージできていないと、必要な画面の準備や社内申請が滞る可能性もあるので、全体像をイメージしたうえで導入いただけるとスムーズかと思います。<br>
あまり技術的に解説することができなかったので、次は実際の Keycloak のローカル環境構築や Laravel での実装方法などについて、より詳しく解説できたらと思います。
