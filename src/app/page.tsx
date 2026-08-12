import Nav      from "@/components/Nav";
import Hero     from "@/components/Hero";
import About    from "@/components/About";
import NowShipping from "@/components/NowShipping";
import Projects from "@/components/Projects";
import Skills   from "@/components/Skills";
import Contact  from "@/components/Contact";
import Footer   from "@/components/Footer";

export default function Home() {
  return (
    <>
      <Nav />
      <main className="relative">
        <Hero />
        <About />
        <NowShipping />
        <Projects />
        <Skills />
        <Contact />
      </main>
      <Footer />
    </>
  );
}
