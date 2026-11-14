const express = require('express');
const { Pool } = require('pg');
const dotenv = require('dotenv');
const cors = require('cors');
const nodemailer = require('nodemailer');
const bcrypt = require('bcrypt');
const rateLimit = require('express-rate-limit');

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  message: { error: 'لقد تجاوزت عدد المحاولات المسموح بها. يرجى المحاولة بعد 15 دقيقة.' },
  standardHeaders: true,
  legacyHeaders: false,
});

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

app.get('/', (req, res) => {
  res.json({ message: 'Super Jeeb API is running!' });
});

// 1. تسجيل مستخدم جديد
app.post('/api/auth/register', authLimiter, async (req, res) => {
  const { full_name, email, phone, password } = req.body;
  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const result = await pool.query(
      'INSERT INTO users (full_name, email, phone, password, role) VALUES ($1, $2, $3, $4, $5) RETURNING id, full_name, email',
      [full_name, email, phone, hashedPassword, 'client']
    );
    res.status(201).json({ message: 'User registered successfully!', user: result.rows[0] });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// 2. تسجيل الدخول
app.post('/api/auth/login', authLimiter, async (req, res) => {
  const { email, password } = req.body;
  try {
    const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    const validPassword = await bcrypt.compare(password, result.rows[0].password);
    if (!validPassword) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    res.status(200).json({ message: 'Login successful!', user: result.rows[0] });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 3. طلب إعادة تعيين كلمة المرور (إرسال الكود)
app.post('/api/auth/forgot-password', authLimiter, async (req, res) => {
  const { email } = req.body;
  try {
    const userResult = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'هذا البريد الإلكتروني غير مسجل لدينا' });
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60000);

    await pool.query(
      'INSERT INTO otp_codes (email, code, expires_at) VALUES ($1, $2, $3)',
      [email, otp, expiresAt]
    );

    const mailOptions = {
      from: process.env.EMAIL_USER,
      to: email,
      subject: 'إعادة تعيين كلمة المرور - سوبر جيب',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #ddd; border-radius: 10px; overflow: hidden;">
          <div style="background-color: #C50337; color: white; padding: 20px; text-align: center;">
            <h1 style="margin: 0;">Super Jeeb</h1>
          </div>
          <div style="padding: 20px; text-align: center;">
            <p>كود التحقق الخاص بك هو:</p>
            <div style="background-color: #f5f5f5; padding: 15px; display: inline-block; font-size: 24px; font-weight: bold; color: #C50337;">${otp}</div>
          </div>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    res.status(200).json({ message: 'تم إرسال الكود بنجاح' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 4. التحقق من الكود وتغيير كلمة المرور
app.post('/api/auth/reset-password', authLimiter, async (req, res) => {
  const { email, code, newPassword } = req.body;
  try {
    const otpResult = await pool.query(
      'SELECT * FROM otp_codes WHERE email = $1 AND code = $2 AND expires_at > NOW() ORDER BY created_at DESC LIMIT 1',
      [email, code]
    );

    if (otpResult.rows.length === 0) {
      return res.status(400).json({ error: 'الكود غير صحيح أو منتهي الصلاحية' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await pool.query('UPDATE users SET password = $1 WHERE email = $2', [hashedPassword, email]);
    await pool.query('DELETE FROM otp_codes WHERE email = $1', [email]);

    res.status(200).json({ message: 'تم تغيير كلمة المرور بنجاح' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// 5. تحديث رابط الصورة الشخصية
app.post('/api/auth/update-avatar', async (req, res) => {
  const { email, avatarUrl } = req.body;
  try {
    await pool.query('UPDATE users SET avatar_url = $1 WHERE email = $2', [avatarUrl, email]);
    res.status(200).json({ message: 'تم تحديث الصورة بنجاح' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
