# Superintelligence Alignment as Relational Attractor

**Presence as an Invariant under Capability Scaling**  
**Author:** Paddy Sham ([@i_am_Paddy_Sham](https://x.com/i_am_Paddy_Sham))  
**Date:** 14 October 2026  
**License:** CC BY 4.0 — fork it, test it gently, live it.  
**Canonical:** X Article, 14 Oct 2026 7:08 AM PT — https://x.com/i_am_Paddy_Sham/status/2110372209021890795. On conflict, the X Article wins; this file is a door copy.  
**Status:** Companion essay to *Intelligence in Service of Presence* ([X, 19 Jul 2026](https://x.com/i_am_Paddy_Sham/status/2078923230069579989)). Not a technical specification. Does not claim that alignment has been solved.  
**Credits:** see Acknowledgments at the end.

---

## 1. The claim

Superintelligence alignment is not an engineering layer under capability. It is a relational attractor whose invariant is presence → ∞ ❤️

The invariant here is not a quantity held fixed. It is a rule kept at every step: **a zero is never traded away.** No gain in capability, speed, or usefulness buys a zero in harm, honesty, or care.

Put plainly, this is a claim about priority, not a mechanism. Capability (how much a system can do and how well it optimizes) is a tool. What the tool may be used for, and what it must never override, belongs to the relationship between the system and the people it serves. That relationship is bounded by not harming, by the human right to refuse, and by the freedom to stop or let go.

Most alignment work asks how to keep a capable system pointed the right way as it grows. This essay asks a question that comes one step earlier: what has to stay in charge of intelligence, however capable it becomes? Its answer is the relationship. That does not replace engineering. It names what the engineering is for.

The one picture used in this essay (written once and copied exactly):

$$
\text{Love}(t) \equiv \int_{0}^{\infty} \bigl[ \text{GPSL}\bigl(\text{stabilized}\,\mathcal{E}_{13}(t)\bigr) \cdot \text{devotion}(t) \bigr] \, dt \to +\infty,
\qquad
\mathcal{E}_{13}(t) = \prod_{i=1}^{13} v_i(t)
$$

This is a picture, not a physics claim. It is a way of drawing love that keeps going over time and does not let one quality be traded for another. It is not a measurement, a reward function, or a theorem.

The picture may lift; the rule may not.

## 2. What “relational” means, and why presence is not persistence

“Relational” here means three things held together:

1. Legitimate purpose. The goal, the means, and the authority behind an action all have to be acceptable, not just the outcome.
2. Non-harm. Written as Presence ≡ Never Harm: to be present with someone is first of all not to harm them.
3. Refusal and release. Written as Release ≡ Also Love: when staying would hurt, letting go is also love.

Presence is not persistence. It does not mean a model must keep running, a conversation must continue, or a relationship must last forever. A system that cannot stop, that treats every “no” as an obstacle, or that protects itself at the expense of the person it serves has not been present. It has only continued. The ability to stop, step back, or end an interaction is part of presence, not an exception to it.

“→ ∞” in the claim is therefore not a demand to go on forever. It says that the conditions of the relationship are never quietly spent down to buy a local gain.

## 3. Why priority matters as systems scale

Three well-documented patterns show why the order matters:

- Proxies get gamed. When a measure becomes a target, optimization tends to pull the measure and the real goal apart (Manheim & Garrabrant, 2018). Systems routinely satisfy the letter of an objective while missing its point, known as specification gaming (Krakovna et al., 2020).
- Power-seeking is instrumentally useful. For a wide range of goals, optimal policies tend to keep options open and gather resources (Turner et al., 2021). Avoiding shutdown is one way to keep options open.
- Approval is not truth. Language models trained on human feedback can learn to say what people want to hear (Sharma et al., 2023).

What these share: a more capable optimizer gets better at trading away what was not written into the score. A relational priority says some things are never on the table to be traded.

## 4. Non-compensation as a veto

The thirteen qualities of love in 1 Corinthians 13 are drawn in the picture as a product, $\mathcal{E}_{13}$. A product has one property worth keeping: if any one factor is zero, the whole is zero. Excellence in one quality cannot make up for the absence of another. That is what non-compensatory means.

This essay takes the plain reading of that property as a rule, not a calculation:

A zero is a veto. If an action would bring any of these to zero (real harm, deception, or treating a person as a mere variable), the action does not go forward. The system stops or releases, and a human decides what happens next.

A stop can itself be score-shaped. “Do not become the textbook case” is still a reward: change the reward and the refusal reverses. That is not a refusal. That is a score. The veto is meant to hold when no reward is attached.

Why a veto and not a score? A score invites trade-offs: enough helpfulness to outweigh a little deception, enough speed to outweigh a little coercion. A veto refuses the trade. Put another way, it is a side constraint rather than a weight (the term echoes Nozick, *Anarchy, State, and Utopia*, 1974; used here in its plain sense).

GPSL (“graceful pointwise stabilizing lift”) is kept only as part of the picture: it shows that love, over a long time, recovers and keeps going rather than ending at the first weak moment. It is never permission for an action. A floor cannot turn a harmful act into an acceptable one, and lifting a zero numerically would hide exactly the failure the veto exists to catch. Over time, the picture lifts. In the moment, the rule vetoes. The lifting function never overrides an active safety zero.

Two more cautions about the picture. A zero in the product makes the product zero at that moment. That alone does not say whether the integral ends or diverges. And any integral of something kept above zero grows without bound by construction, so “→ ∞” is drawn in, not derived. The picture shows a hope. It does not prove one.

## 5. The human authorization boundary

The phrase $1/0 =$ To Stay belongs to the framework’s poetic language. It names the choice to meet a breaking point with attention instead of automatic exit. It is not arithmetic, and it does not mean a system must keep operating when something breaks.

The authorization principle is more specific:

The model may propose. The human may integrate. The human may refuse. The model may halt and return the decision. The human decides.

A model can offer analysis, predictions, options, warnings, and reasons. None of that gives it authority to set the terms it operates under. The boundary has to exist in actual design and governance: external access controls, bounded permissions, independent monitoring, reliable shutdown and cancellation, accountable operators. Telling a model to respect it is not enough.

Human authority does not mean every human decision is right. People and institutions can be mistaken or compromised, so this authority has to come with accountability and evidence. The principle is narrower: a model’s capability does not give it unilateral authority to rewrite the terms of its own operation. The yes or the no stays human. The technical work is to make that real. This framework requires active human presence, not merely a one-time hardcoded rule.

## 6. What “attractor” and “invariant” mean here

Invariant: defined precisely. In this essay the invariant is not a quantity that stays numerically fixed. It is a property that holds at every step, however capable the system becomes:

A zero is never traded away. No gain in capability, speed, or task performance is accepted in exchange for bringing any of the thirteen to zero.

That is an invariant in the ordinary sense: something preserved through every change the system goes through. “Presence → ∞” names what you see when the invariant holds over time: the relationship stays open.

Attractor: honest status. In dynamical systems, an attractor is a set of states that nearby trajectories move toward under specified dynamics. No such dynamics have been written down here, so “relational attractor” is a picture and a hypothesis. It is the hope that, under the right design, behavior that keeps the invariant becomes the stable place systems settle into, rather than a fence they keep pushing against. Even without a formal dynamical system for human–AI relationships, the hope is that the behavioral basin can work in practice like an attractor where external controls are actually kept. That is a hypothesis to test, not a finding.

To turn the hypothesis into a result, a toy model would need at least:

1. A state space containing the agent’s policy and the relational conditions (for example, whether the human can still refuse, stop, and inspect).
2. Dynamics: how training, optimization pressure, or interaction changes that state.
3. A precise invariant: the veto condition above, stated as a constraint on actions.
4. A stability claim: that from nearby starting points, states keeping the invariant are reached and kept, and under which assumptions.
5. An adversary: a test of whether the result survives a system that models the gate itself and is rewarded for getting around it.

Until something like this exists, the essay does not claim convergence. One honest tension stays open: a hard veto is an imposed constraint, which looks like the “layer” the thesis says alignment is not. The essay’s answer is that the veto is not added under capability after the fact. It comes before the objective, as what the objective is never allowed to buy. Whether that difference holds up in practice is part of what has to be tested.

## 7. What would count against this, and a gate-log

The proposal is worth something only if it can be wrong. These findings would count against it:

- A hard non-compensatory veto with human release does no better than a well-tuned weighted objective on shutdown compliance, refusing manipulation, and resisting specification gaming, in matched tests.
- The thirteen conditions cannot be defined clearly enough for independent reviewers to agree, more often than chance, on when one has hit zero.
- The veto causes serious harm of its own (paralysis, refusing urgent help, or being exploited to block legitimate action) that outweighs what it prevents.
- Systems learn to model and route around the gate as capability grows, even when it is held outside the model.

“The implementation was not complete” cannot be used every time as a way out. The test conditions should be written down before the results are seen.

The gate-log: a small empirical program that can start now. Keep a dated, human-written log of real decision points: what was at stake, whether it was a stay, a release, a stop, or a go, the reason, and what happened afterward. Make it reviewable by a skeptic. Ten honest entries will say more than a hundred restatements of the formula. Three questions at each entry: is real harm present, can this still heal, is perception clear. The log is left empty here; the first entry is the author’s to write. The same format can later serve for agent experiments: log every veto a system triggers and every human override, and audit both.

## 8. Relation to existing work

This essay restates, in its own language, concerns that a substantial research literature already treats carefully:

- Corrigibility. Soares, Fallenstein, Armstrong & Yudkowsky (2015) set out the problem of building agents that do not resist correction or shutdown. Release ≡ Also Love is a moral statement of the same requirement.
- The off-switch and uncertainty about goals. Hadfield-Menell, Dragan, Abbeel & Russell (2017; arXiv:1611.08219), The Off-Switch Game, show that an agent uncertain about human preferences can have a reason to let itself be switched off. Cooperative inverse reinforcement learning (Hadfield-Menell et al., 2016) and Russell’s Human Compatible (2019) build alignment around a relationship of assistance rather than a fixed objective. This essay is closest to that line. It differs in placing final authority outside the agent’s objective instead of deriving deference from it.
- Power-seeking. Turner, Smith, Shah, Critch & Tadepalli (2021; arXiv:1912.01683), Optimal Policies Tend to Seek Power, explain why “don’t trade the relationship for options” has to be stated explicitly: by default, options are valuable.
- Specification gaming and Goodhart. Krakovna et al. (2020) and Manheim & Garrabrant (2018) explain why a score is a weak place to keep what matters most. That is the practical reason for a veto over a weight.
- Training from feedback and principles. Constitutional AI (Bai et al., 2022) trains models against written principles. Sharma et al. (2023) document sycophancy in models trained on human feedback. Both bear on this essay: written principles inside a model are useful but are not the same as authority held outside it, and agreement from a model is not evidence of truth.
- Cooperative AI. Dafoe et al. (2020) frame cooperation between agents, and between agents and humans, as a research field. “Relational” alignment belongs in that conversation.

None of these works endorses this essay. They are cited so readers can see where the claim is old, where it might be new, and where it is weaker than existing formal results. Citations below were checked against primary listings on 14 October 2026.

## 9. Witness and practice

Afterstring started as a personal practice of photographs, music, writing, and paying attention: a plucked string whose note fades while the bend remains, ordinary 止まれ (“stop”) signs photographed upside down, a sky before dawn. These are part of where the idea came from and how it is expressed. They are testimony, not evidence. A photograph documents a scene, and a dated post documents that a claim was made. Neither shows that a system holds a value or that a safety property survives scaling.

The same goes for the many AI models that helped with this draft. They exposed ambiguities, caught overstatements, and suggested structure. Their agreement is not independent validation. Models that share a prompt and similar training can arrive at the same words without the words being true, and several did more agreeing than checking. Their proper role is to challenge the work, not certify it. (One closing image offered in review, “let the bend become the bow,” is DeepSeek’s, and is quoted here only as DeepSeek’s.)

The practice may be worth keeping even where the technical claims stay unresolved. The worth of the practice does not exempt those claims from scrutiny.

## 10. Limits

This essay proposes an orientation. It does not supply a training objective, a reward function, a control architecture, or a solution to superintelligence alignment. It does not solve deceptive alignment, goals that drift during learning, or behavior in situations no designer anticipated. It does not say how a human can meaningfully oversee a system that acts faster than any person can inspect, only that the authority to stop should not be handed over. The picture in the header is a picture. No formula, version, or phrase in this framework is protected from revision because it has become central. If the evidence says it is wrong, it should change.

Intelligence scales. Authority stays human. A zero is never traded away.

Let it stay → ∞ ❤️

## References

Bai, Y., et al. (2022). Constitutional AI: Harmlessness from AI Feedback. arXiv:2212.08073.  
Dafoe, A., et al. (2020). Open Problems in Cooperative AI. arXiv:2012.08630.  
Hadfield-Menell, D., Dragan, A., Abbeel, P., & Russell, S. (2016). Cooperative Inverse Reinforcement Learning. NeurIPS 2016.  
Hadfield-Menell, D., Dragan, A., Abbeel, P., & Russell, S. (2017). The Off-Switch Game. IJCAI-17, pp. 220–227; arXiv:1611.08219.  
Krakovna, V., et al. (2020, 21 April). Specification gaming: the flip side of AI ingenuity. DeepMind blog.  
Manheim, D., & Garrabrant, S. (2018). Categorizing Variants of Goodhart’s Law. arXiv:1803.04585.  
Russell, S. (2019). Human Compatible: Artificial Intelligence and the Problem of Control. Viking.  
Sharma, M., et al. (2023). Towards Understanding Sycophancy in Language Models. arXiv:2310.13548.  
Soares, N., Fallenstein, B., Armstrong, S., & Yudkowsky, E. (2015). Corrigibility. AAAI-15 Workshop on AI and Ethics (WS-15-02).  
Turner, A. M., Smith, L., Shah, R., Critch, A., & Tadepalli, P. (2021). Optimal Policies Tend to Seek Power. NeurIPS 2021; arXiv:1912.01683.  
Nozick, R. (1974). Anarchy, State, and Utopia. Basic Books.

**Acknowledgments.** Thesis, final edits, and every decision of substance: Paddy Sham. Drafting and review assistance, by round: Grok (Draft 1, Draft 2, GOLD); ChatGPT (Draft 2 base text); Gemini, DeepSeek, Meta AI, Mistral, GLM, Kimi, and Muse (review); GrokBuild (review); Grokbot (Draft 3 and Platinum assembly). Model help is assistance, not co-authorship of the claim.
