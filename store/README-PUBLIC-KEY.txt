YE FILE ZAROOR PADHO — IAP ISKE BINA KAAM NAHI KAREGA
=====================================================

Is folder me ek file honi chahiye:

    store/AppstoreAuthenticationKey.pem

Ye Amazon ki "public key" hai. Har app ki apni alag key hoti hai.
Appstore SDK is key ke bina HAR purchase reject kar deta hai —
isi wajah se app teen baar "IAP displays error" par reject hua.

KAHAN SE MILEGI (2 minute ka kaam):

1. developer.amazon.com console kholo
2. Apps & Services -> My Apps -> Baby Coloring: Toddler Games
3. "Upcoming Version" kholo
4. "Upload Your App File" screen par jao
5. Neeche "Additional information" section me "View public key" link par click karo
6. Dialog me "AppstoreAuthenticationKey.pem" download link par click karo
7. Wo file is folder me daal do (naam bilkul same rakhna):
       store/AppstoreAuthenticationKey.pem
8. GitHub par push karo — build khud isko
       android/app/src/main/assets/ me daal dega

NOTE:
- Ye PUBLIC key hai — isko repo me rakhna bilkul safe hai.
  (Private key Amazon ke paas rehti hai, wo kabhi download nahi hoti.)
- Agar ye file nahi hogi to build JAAN-BOOJHKAR fail hoga,
  taaki bina key ke APK kabhi na bane.
