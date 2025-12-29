import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscure = true;

  // EMAIL LOGIN
  Future<void> loginUser() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      // ❌ DO NOTHING ELSE
      // AppGate will handle navigation
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Login failed")),
      );
    }
  }


  // GOOGLE LOGIN (NEW API, 2025 COMPATIBLE)
  Future<void> signInWithGoogle() async {
    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      final userCredential =
          await FirebaseAuth.instance.signInWithProvider(googleProvider);

      Navigator.pushReplacementNamed(context, '/select-city');
    } catch (e) {
      print("GOOGLE LOGIN ERROR: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google login failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 40),

              const Text(
                "Vayufy",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),
              const Text(
                "Sign in to continue",
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),

              const SizedBox(height: 40),

              // EMAIL FIELD
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // PASSWORD FIELD
              TextField(
                controller: passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: "Password",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // LOGIN BUTTON
              GestureDetector(
                onTap: loginUser,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      "Continue",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                children: const [
                  Expanded(child: Divider(thickness: 0.6)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      "or",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                  Expanded(child: Divider(thickness: 0.6)),
                ],
              ),

              const SizedBox(height: 25),

              // GOOGLE LOGIN BUTTON
              GestureDetector(
                onTap: signInWithGoogle,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        "https://upload.wikimedia.org/wikipedia/commons/0/09/IOS_Google_icon.png",
                        height: 22,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Continue with Google",
                        style: TextStyle(fontSize: 15, color: Colors.black87),
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Center(
                child: RichText(
                  text: TextSpan(
                    text: "New user? ",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: "Create account",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushNamed(context, '/signup');
                          },
                      ),
                    ],
                  ),
                ),
              ),



            ],
          ),
        ),
      ),
    );
  }
}
