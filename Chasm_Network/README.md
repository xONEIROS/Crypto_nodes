## Server Specifications
Minimum Requirements:

1 vCPU
1GB RAM
20GB Disk
Static IP

## Suggested Requirements:

2 vCPU
4GB RAM
50GB SSD
Static IP

# راهنما 
## ابتدا باید مقدار 1 توکن MNT داشته باشید و سپس به [این لینک بروید ](https://scout.chasm.net/private-mint) | بعد از مینت کردن NFT ،  وارد [داشبورد خودتون](https://scout.chasm.net/dashboard) بشید 

![image](https://github.com/user-attachments/assets/7e557437-88bc-48dc-bdb2-c03b5f99b3eb)

## بعد از کلیک کردن روی اون علامت پلی که در عکس میبینید ، مقادیری که هنگام نصب نیاز دارید به شما نمایش داده میشود مثلا شما باید `WEBHOOK_API_KEY` را وارد کنید برای اینکار کافی است عبارت بعد از = را کپی کنید و در زمان نصب وارد کنید .

### برای نصب میتوانید کد زیر را کپی کنید و در سرور پست کنید و سپس اینتر بزنید !
```
wget "https://raw.githubusercontent.com/xONEIROS/Crypto_nodes/main/main.sh" -O main.sh && sed -i 's/\r$//' main.sh && chmod 777 main.sh && ./main.sh
```

# عدد 2 برای نصب نود این پروژه است

### دوستان این نود روی NAT ip vps ها کار نمیکنه باید پابلیک ای پی داشته باشید ، میتونید ip v6 ( اگر سرورتون ساپورت میکنه فعال کنید ببرید پشت دامنه )

# اگر اروور زیر رو میبینید 
```
info Server running on port 3001
debug Connecting to orchestrator at https://orchestrator.chasm.net
46 |         ws.on("error", (error) => {
47 |             throw new Error(`Handshake failed: ${error.message}\n${JSON.stringify(error, null, 2)}`);
48 |         });
49 |         ws.on("close", (code, reason) => {
50 |             if (code !== 1000) {
51 |                 throw new Error(`❌ Handshake with orchestrator at ${ORCHESTRATOR_URL} failed with error:\n${reason}`);
                           ^
error: ❌ Handshake with orchestrator at https://orchestrator.chasm.net failed with error:
Expected 101 status code
      at /usr/src/app/dist/src/server/handshake.js:51:23
      at emit (node:events:180:48)
      at ws:95:44
```

## مراحل زیر رو دنبال کنید ( راه حل اول )

```
docker stop scout
docker rm scout
```
```
docker pull chasmtech/chasm-scout:0.0.4
```
```
docker run -d --restart=always --env-file ./.env -p 3001:3001 --name scout chasmtech/chasm-scout:0.0.4
```

### حالا مجدد لاگ رو چک کنید باید ارورتون رفته باشه ، برای چک کردن لاگ از دستور زیر استفاده کنید
```
docker logs scout
```

## راه حل دوم 

به سایت [nftok](https://ngrok.com/) بروید و ثبت نام کنید
بعد از رورد از هدر بالا روی گزینه اوبونتو کلیک کنید
![image](https://github.com/user-attachments/assets/a0fc304f-ab10-47bb-a552-0d1dd4d89848)

حالا از پنجره زیر همونجا دستورات را به ترتیبی که در عکس علاما زدم کپی کنید
![image](https://github.com/user-attachments/assets/75e79c1f-b83c-4490-90e7-35efd9837991)


با دستور زیر یک اسکرین جدید بسازید 
```
screen -S ngrok
```
حالا دستور زیر را اجرا کنید
```
screen ngrok http 3001
```
بعدش یک چیزی مثل عکس زیر میبینید که باید لینکی که داخل کادر قرمز است رو کپی کنید ( مهمه یادتون نره )
![image](https://github.com/user-attachments/assets/616c0dea-9b05-4993-b6f8-f260baf04e3f)
حالا با زدن کلید های Crtl + A + D از این اسکرین بیاید بیرون
حالا دستور `nano .env` ذا اجذا کنید . اون لینکی کپی کردید رو بزارید جلو `=WEBHOOK_URL` ( یعنی لینکی که هست رو پاک کنید و بعدش پیست کنید ، حالا با دستور crtl + x و بعدش Y و اینتر فایل رو سیو کنید و ببندید
حالا کافیه دستورات زیر رو اجرا کنید
```
docker stop scout
docker rm scout
docker run -d --restart=always --env-file ./.env -p 3001:3001 --name scout johnsonchasm/chasm-scout
```
## تمام ، بعد از 10 15 دقیقه بهتون توی سایت زرد میشه و حدودا یکی دو ساعت بعدش سبز 

اگر دوست داشتید مارو هم یک ستاره ای فورکی لایکی چیزی کنید :))))))))))))))))

