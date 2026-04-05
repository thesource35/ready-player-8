"use client";
import { useState, useRef, useEffect } from "react";

interface Message {
  role: "user" | "assistant";
  content: string;
}

export default function AIPage() {
  const [messages, setMessages] = useState<Message[]>([
    { role: "assistant", content: "I'm Angelic — your AI construction assistant with access to 56 live data tools. Ask me about site status, crew deployment, equipment, budgets, RFIs, or anything else on your jobsite." },
  ]);
  const [input, setInput] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);

  const starters = [
    "What's the status of Riverside Lofts?",
    "Show me available excavators under $1,000/day",
    "Draft an RFI for a concrete delay",
    "What's our bid win rate this year?",
    "Calculate rental cost for 2 boom lifts for 30 days",
  ];

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  async function send() {
    const text = input.trim();
    if (!text || isLoading) return;

    const userMsg: Message = { role: "user", content: text };
    const newMessages = [...messages, userMsg];
    setMessages(newMessages);
    setInput("");
    setIsLoading(true);

    try {
      const res = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ messages: newMessages.map(m => ({ role: m.role, content: m.content })) }),
      });

      if (!res.ok || !res.body) {
        throw new Error("API not available");
      }

      // Stream the response
      const reader = res.body.getReader();
      const decoder = new TextDecoder();
      let assistantContent = "";

      setMessages(prev => [...prev, { role: "assistant", content: "" }]);

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        const chunk = decoder.decode(value, { stream: true });
        assistantContent += chunk;

        setMessages(prev => {
          const updated = [...prev];
          updated[updated.length - 1] = { role: "assistant", content: assistantContent };
          return updated;
        });
      }
    } catch {
      // Fallback: demo response when API key is not set
      setMessages(prev => [...prev, {
        role: "assistant",
        content: `Great question about "${text}". In the full ConstructionOS platform, I connect to 56 MCP tools with real-time access to all your project data, crew deployment, equipment tracking, financial records, and more.\n\nTo enable live AI responses, configure AI in the Integration Hub (/hub).\n\nHere's what I can help with:\n• Project status & risk scoring\n• Equipment rental recommendations\n• RFI and submittal drafting\n• Budget analysis & forecasting\n• Safety compliance checks\n• Bid preparation assistance`
      }]);
    }

    setIsLoading(false);
  }

  return (
    <div className="max-w-3xl mx-auto px-4 py-8 flex flex-col" style={{ minHeight: "calc(100vh - 64px)" }}>
      <div className="rounded-2xl p-6 mb-6" style={{ background: "#0F1C24" }}>
        <div className="text-xs font-bold tracking-widest text-[#8A8FCC] mb-1">ANGELIC AI</div>
        <h1 className="text-2xl font-black">AI Construction Assistant</h1>
        <p className="text-sm text-[#9EBDC2]">56 MCP tools &middot; Live data access &middot; Claude-powered &middot; Streaming responses</p>
      </div>

      {/* Starters */}
      {messages.length <= 1 && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-2 mb-6">
          {starters.map(s => (
            <button key={s} onClick={() => { setInput(s); }} className="text-left p-3 rounded-xl text-sm cursor-pointer" style={{ background: "#0F1C24", border: "1px solid rgba(51,84,94,0.2)", color: "#9EBDC2" }}>{s}</button>
          ))}
        </div>
      )}

      {/* Messages */}
      <div className="flex-1 space-y-4 mb-6">
        {messages.map((m, i) => (
          <div key={i} className={`flex ${m.role === "user" ? "justify-end" : "justify-start"}`}>
            <div className={`max-w-[80%] rounded-2xl p-4 ${m.role === "user" ? "text-black" : ""}`} style={{ background: m.role === "user" ? "linear-gradient(135deg, #F29E3D, #FCC757)" : "#0F1C24" }}>
              {m.role === "assistant" && <div className="text-xs font-bold text-[#8A8FCC] mb-1">Angelic</div>}
              <p className="text-sm leading-relaxed whitespace-pre-wrap">{m.content}{isLoading && i === messages.length - 1 && m.role === "assistant" && <span className="animate-pulse"> ▊</span>}</p>
            </div>
          </div>
        ))}
        <div ref={bottomRef} />
      </div>

      {/* Input */}
      <div className="flex gap-2">
        <input
          value={input}
          onChange={e => setInput(e.target.value)}
          onKeyDown={e => e.key === "Enter" && send()}
          placeholder="Ask about sites, crew, budgets, equipment..."
          className="flex-1"
          disabled={isLoading}
        />
        <button onClick={send} disabled={isLoading} className="px-6 py-3 rounded-xl font-bold text-black shrink-0 cursor-pointer" style={{ background: isLoading ? "#33545E" : "linear-gradient(90deg, #F29E3D, #FCC757)" }}>
          {isLoading ? "..." : "Send"}
        </button>
      </div>
    </div>
  );
}
