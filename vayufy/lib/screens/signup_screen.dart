import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscure = true;
  bool loading = false;

  // EMAIL SIGNUP
  Future<void> signUpUser() async {
    if (loading) return;
    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      Navigator.pushReplacementNamed(context, '/health');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Signup failed")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // GOOGLE SIGNUP
  Future<void> signUpWithGoogle() async {
    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      await FirebaseAuth.instance.signInWithProvider(googleProvider);

      Navigator.pushReplacementNamed(context, '/health');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google signup failed: $e")),
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
                "Create Account",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),
              const Text(
                "Sign up to continue",
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

              // SIGNUP BUTTON (MATCHES LOGIN)
              GestureDetector(
                onTap: signUpUser,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      loading ? "Creating..." : "Create Account",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // OR DIVIDER (SAME AS LOGIN)
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

              // GOOGLE SIGNUP BUTTON (SAME AS LOGIN)
              GestureDetector(
                onTap: signUpWithGoogle,
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

              // BOTTOM TEXT (MATCHES LOGIN STYLE)
              Center(
                child: RichText(
                  text: TextSpan(
                    text: "Already registered? ",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                        text: "Login",
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pop(context);
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
