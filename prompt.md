buat aplikasi blockchain lengkap diatas hyperledger dengan bahasa javascript. meliputi smart contract, API, dan frontend UI menggunakan vue+vite.

User roles:
- Authority: 
  - terdiri dari beberapa address yang bisa diregister via UI
  - bisa mendaftarkan kapal (vessel)
  - bisa mendaftarkan user Ship Owner
  - bisa menjadwalkan survey
  - bisa mencatat findings
  - bisa mengeluarkan certificate jika semua findings sudah selesai
  
- Ship Owner
  - terdiri dari beberapa address yang didaftarkan via UI oleh BKI Authority
  - bisa melihat findings dan menyelesaikan findings

- Public
  - bisa melihat cerfificate 
  - bisa melihat daftar kapal yang sudah terdaftar
  - bisa melihat daftar user Ship Owner
  - bisa melihat daftar findings
  - bisa melihat daftar survey yang sudah dilakukan
  - bisa memverifikkasi sertifikat

Business Process:

Biro Klasifikasi Indonesia (BKI) merupakan lembaga yang bertanggung jawab dalam melakukan survei dan sertifikasi terhadap kapal-kapal yang beroperasi di wilayah yurisdiksi Indonesia maupun internasional. Proses sertifikasi yang dilakukan BKI diawali dengan kegiatan survei menyeluruh terhadap kondisi kapal, yang mencakup aspek struktural seperti badan (hull) kapal dan aspek teknis seperti sistem permesinan.

Apabila dalam proses survei ditemukan adanya ketidaksesuaian atau temuan (findings), maka BKI akan mencatat temuan-temuan tersebut dan memberikan waktu tertentu kepada pemilik kapal untuk melakukan perbaikan atau tindakan korektif. Setelah seluruh temuan diselesaikan dan diverifikasi kembali oleh surveyor BKI, kapal tersebut dapat dinyatakan memenuhi persyaratan klasifikasi dan diberikan sertifikat klas atau "Class Certificate". Sertifikat ini menandakan bahwa kapal tersebut telah sesuai dengan standar teknis dan keselamatan yang ditetapkan oleh BKI, khususnya terkait dengan integritas struktur fisik dan keandalan sistem mesin kapal.

Hingga saat ini, BKI telah menerbitkan sertifikat klas untuk lebih dari 15.000 kapal, yang mencerminkan peran strategis BKI dalam mendukung keselamatan pelayaran dan kelayakan kapal di tingkat nasional maupun global.