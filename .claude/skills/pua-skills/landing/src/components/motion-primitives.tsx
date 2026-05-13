import { useState, useRef, useEffect, type ReactNode } from "react"
import { motion, useInView, AnimatePresence, LayoutGroup } from "motion/react"

/* ── FadeIn ── */
export function FadeIn({ children, delay = 0 }: { children: ReactNode; delay?: number }) {
  const ref = useRef<HTMLDivElement>(null)
  const inView = useInView(ref, { once: true, margin: "-60px" })
  return (
    <motion.div
      ref={ref}
      initial={{ opacity: 0, y: 20 }}
      animate={inView ? { opacity: 1, y: 0 } : {}}
      transition={{ duration: 0.5, delay }}
    >
      {children}
    </motion.div>
  )
}

/* ── Stagger ── */
export function Stagger({ children, className }: { children: ReactNode; className?: string }) {
  const ref = useRef<HTMLDivElement>(null)
  const inView = useInView(ref, { once: true, margin: "-40px" })
  return (
    <motion.div
      ref={ref}
      className={className}
      initial="hidden"
      animate={inView ? "visible" : "hidden"}
      variants={{ visible: { transition: { staggerChildren: 0.08 } }, hidden: {} }}
    >
      {children}
    </motion.div>
  )
}

export function StaggerItem({ children }: { children: ReactNode }) {
  return (
    <motion.div variants={{ hidden: { opacity: 0, y: 16 }, visible: { opacity: 1, y: 0, transition: { duration: 0.4 } } }}>
      {children}
    </motion.div>
  )
}

/* ── TextReveal ── */
export function TextReveal({ text, delay = 0 }: { text: string; delay?: number }) {
  return (
    <span style={{ display: "inline-flex", overflow: "hidden" }}>
      {text.split("").map((ch, i) => (
        <motion.span
          key={i}
          initial={{ y: "100%" }}
          animate={{ y: 0 }}
          transition={{ duration: 0.5, delay: delay + i * 0.04, ease: [0.22, 1, 0.36, 1] }}
          style={{ display: "inline-block" }}
        >
          {ch === " " ? "\u00A0" : ch}
        </motion.span>
      ))}
    </span>
  )
}

/* ── AnimatedBar ── */
export function AnimatedBar({ value }: { value: number }) {
  const ref = useRef<HTMLDivElement>(null)
  const inView = useInView(ref, { once: true })
  return (
    <div ref={ref} style={{ flex: 1, height: "0.5rem", borderRadius: "0.25rem", background: "var(--border-dim, rgba(255,255,255,0.06))", overflow: "hidden" }}>
      <motion.div
        initial={{ width: 0 }}
        animate={inView ? { width: `${value}%` } : {}}
        transition={{ duration: 0.8, ease: "easeOut" }}
        style={{ height: "100%", borderRadius: "0.25rem", background: "var(--accent, #adfb1b)" }}
      />
    </div>
  )
}

/* ── SpotlightCard ── */
export function SpotlightCard({ children, className, spotlightColor }: { children: ReactNode; className?: string; spotlightColor?: string }) {
  const ref = useRef<HTMLDivElement>(null)
  const color = spotlightColor ?? "rgba(173, 250, 27, 0.06)"

  function handleMove(e: React.MouseEvent) {
    const rect = ref.current?.getBoundingClientRect()
    if (!rect) return
    ref.current!.style.setProperty("--x", `${e.clientX - rect.left}px`)
    ref.current!.style.setProperty("--y", `${e.clientY - rect.top}px`)
  }

  return (
    <div
      ref={ref}
      className={`card spotlight-card${className ? ` ${className}` : ""}`}
      onMouseMove={handleMove}
      style={{ "--spot-color": color } as React.CSSProperties}
    >
      {children}
    </div>
  )
}

/* ── AnimatedTabs ── */
export function AnimatedTabs({ tabs, activeTab, onChange, layoutId, className }: {
  tabs: { id: string; label: string }[]
  activeTab: string
  onChange: (id: string) => void
  layoutId: string
  className?: string
}) {
  return (
    <LayoutGroup id={layoutId}>
      <div className={`tabs${className ? ` ${className}` : ""}`} role="tablist">
        {tabs.map(tab => (
          <button
            key={tab.id}
            role="tab"
            aria-selected={activeTab === tab.id}
            className={`tab${activeTab === tab.id ? " active" : ""}`}
            onClick={() => onChange(tab.id)}
          >
            {tab.label}
            {activeTab === tab.id && (
              <motion.div className="tab-indicator" layoutId={`${layoutId}-indicator`} transition={{ type: "spring", stiffness: 400, damping: 30 }} />
            )}
          </button>
        ))}
      </div>
    </LayoutGroup>
  )
}

/* ── Accordion ── */
export function Accordion({ items }: { items: { id: string; trigger: ReactNode; content: ReactNode }[] }) {
  const [open, setOpen] = useState<string | null>(items[0]?.id ?? null)
  return (
    <div className="accordion">
      {items.map(item => {
        const isOpen = open === item.id
        return (
          <div key={item.id} className="accordion-item">
            <button className={`accordion-trigger${isOpen ? " open" : ""}`} onClick={() => setOpen(isOpen ? null : item.id)}>
              {item.trigger}
              <span className="accordion-chevron" style={{ transform: isOpen ? "rotate(180deg)" : "rotate(0)" }}>▾</span>
            </button>
            <AnimatePresence initial={false}>
              {isOpen && (
                <motion.div
                  initial={{ height: 0, opacity: 0 }}
                  animate={{ height: "auto", opacity: 1 }}
                  exit={{ height: 0, opacity: 0 }}
                  transition={{ duration: 0.25, ease: "easeInOut" }}
                  style={{ overflow: "hidden" }}
                >
                  <div className="accordion-content">{item.content}</div>
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        )
      })}
    </div>
  )
}

/* ── Marquee ── */
export function Marquee({ children, speed = 30, className }: { children: ReactNode; speed?: number; className?: string }) {
  return (
    <div className={`marquee${className ? ` ${className}` : ""}`} style={{ overflow: "hidden" }}>
      <motion.div
        className="marquee-track"
        animate={{ x: ["0%", "-50%"] }}
        transition={{ duration: speed, repeat: Infinity, ease: "linear" }}
        style={{ display: "flex", gap: "0.75rem", width: "max-content" }}
      >
        {children}
        {children}
      </motion.div>
    </div>
  )
}

/* ── TextShimmer ── */
export function TextShimmer({ children, duration = 2 }: { children: ReactNode; duration?: number }) {
  return (
    <motion.span
      style={{
        backgroundImage: "linear-gradient(90deg, var(--text-secondary) 0%, var(--accent, #adfb1b) 50%, var(--text-secondary) 100%)",
        backgroundSize: "200% 100%",
        WebkitBackgroundClip: "text",
        WebkitTextFillColor: "transparent",
        backgroundClip: "text",
      }}
      animate={{ backgroundPosition: ["200% 0%", "-200% 0%"] }}
      transition={{ duration, repeat: Infinity, ease: "linear" }}
    >
      {children}
    </motion.span>
  )
}

/* ── BorderBeam ── */
export function BorderBeam({ children, duration = 4 }: { children: ReactNode; duration?: number }) {
  return (
    <div style={{ position: "relative", borderRadius: "0.75rem", overflow: "hidden" }}>
      <motion.div
        style={{
          position: "absolute", inset: -1, borderRadius: "inherit", padding: 1,
          background: "conic-gradient(from 0deg, transparent 60%, var(--accent, #adfb1b) 80%, transparent 100%)",
          WebkitMask: "linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0)",
          WebkitMaskComposite: "xor",
          maskComposite: "exclude",
        }}
        animate={{ rotate: 360 }}
        transition={{ duration, repeat: Infinity, ease: "linear" }}
      />
      <div style={{ position: "relative" }}>{children}</div>
    </div>
  )
}

/* ── GlowBorder ── */
export function GlowBorder({ children }: { children: ReactNode }) {
  return (
    <div className="glow-border">
      {children}
    </div>
  )
}

/* ── NumberTicker ── */
export function NumberTicker({ value, className, suffix = "" }: { value: string; className?: string; suffix?: string }) {
  const ref = useRef<HTMLSpanElement>(null)
  const inView = useInView(ref, { once: true })
  const numMatch = value.match(/[\d.]+/)
  const prefix = value.replace(/[\d.]+.*/, "")
  const num = numMatch ? parseFloat(numMatch[0]) : 0
  const rest = numMatch ? value.slice((numMatch.index ?? 0) + numMatch[0].length) : ""
  const [display, setDisplay] = useState("0")

  useEffect(() => {
    if (!inView) return
    const steps = 20
    const step = num / steps
    let current = 0
    let frame = 0
    const interval = setInterval(() => {
      frame++
      current = Math.min(current + step, num)
      setDisplay(Number.isInteger(num) ? Math.round(current).toString() : current.toFixed(1))
      if (frame >= steps) { clearInterval(interval); setDisplay(numMatch ? numMatch[0] : "0") }
    }, 30)
    return () => clearInterval(interval)
  }, [inView])

  return <span ref={ref} className={className}>{prefix}{display}{rest}{suffix}</span>
}
