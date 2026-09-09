# Game Introduction & Core Identity

> Defining BiGuess as a face-to-face party game for the blueprint

---

## **User:**

The file is now ready, let me introduce you the game:

- **BiGuess** is an offline party game played face-to-face where everyone sits together, picks a topic, and starts a round on their own phone. Each player turns their screen outward toward the group so everyone else can see their secret character except themselves. Players then take turns asking the group quick **Yes or No** questions about their own hidden image, racing to be the first to deduce who they are through pure real-life conversation and laughter.

---

## **ChatGPT:**

This is the right place to begin. The blueprint is currently an empty structure, so we can build it from first principles instead of forcing the existing app into it.

Your description also reveals the most important thing about BiGuess:

> **The phone does not contain the game. The people do.**

The app's role is to privately assign each player something they cannot see, show it to everyone else, and then largely disappear while the real interaction happens face-to-face.

I would make one small but important correction before we turn your description into the official definition: don't use **“character”** as the fundamental object. That works for anime and movies, but later you want football players, countries, foods, scholars, and other subjects. The product language needs to survive all of those.

I would use **identity** or **card** at the product level.

So our working definition becomes:

> **BiGuess is an offline, face-to-face party guessing game where two or more players sit together, choose a topic, and each receive a hidden identity on their own phone. Players turn their screens outward so everyone except the phone's owner can see the identity. Taking turns, each player asks the group Yes-or-No questions and uses the answers to figure out who—or what—they are. The phones handle the setup and randomization; the actual game happens through real conversation, deduction, reactions, and laughter.**

I think this is substantially stronger than calling it simply an “offline guessing game.”

## The Big Idea

Before filling the rest of the blueprint, I would formally define BiGuess around this concept:

**BiGuess turns smartphones into reusable mystery cards for real-world social play.**

Traditionally, this kind of game needs printed cards, prepared lists, physical headbands/cards, someone assigning identities, or improvised pieces of paper.

BiGuess removes that preparation:

**Choose → Randomize → Show others → Play in real life.**

And then the app intentionally gets out of the way.

That last part is crucial.

We are **not** building a digital party game where everyone spends the session tapping buttons.

We are building a **digital facilitator for a physical social game**.

That distinction should influence almost every future product decision.

---

## Why BiGuess exists

I'd write the first section of the blueprint approximately like this:

### Vision

**BiGuess exists to make spontaneous face-to-face guessing games effortless.**

People should be able to sit together, open their phones, choose something they all enjoy, and begin playing within seconds—without preparing cards, printing images, assigning characters manually, creating accounts, joining online rooms, or depending on an internet connection.

BiGuess uses technology only for the parts technology improves: choosing content, assigning hidden identities, randomizing cards, avoiding unwanted repetitions, organizing large collections, and making new topics instantly accessible.

The conversation itself remains human.

Players look at each other, ask questions, argue about answers, make bad guesses, recognize inside jokes, help or mislead one another according to their own house rules, and enjoy the reactions happening around the table.

**BiGuess should reduce the friction required to start real-world fun without replacing that fun with screen interaction.**

---

That gives us a very important design test.

From now on, whenever we consider a feature, we can ask:

> **Does this help people start or enjoy the face-to-face interaction, or does it unnecessarily pull their attention back toward the phone?**

If it's the second, the feature needs a very strong justification.

For example:

**Good fit**
- topic selection
- packs
- randomization
- difficulty
- avoiding repeats
- content filters
- quick reroll
- readable cards
- offline content
- optional session configuration

**Potentially bad fit**
- requiring players to record every question
- forcing players to confirm every turn
- mandatory countdowns during questioning
- real-time server synchronization for actions everyone can already see
- constantly updating score screens
- chat
- online matchmaking in the core experience

Not because those technologies are inherently bad.

Because they may be bad **for BiGuess**.

---

There is one other product question hidden inside your description that we should settle early.

You wrote:

> “racing to be the first to deduce who they are”

That implies a competitive shared round where **everyone has an identity simultaneously**, everyone asks questions in turns, and the first person to correctly identify theirs wins.

That's a clear and good game model.

I think we should make that the **canonical BiGuess mode**, rather than keeping the previous ambiguity where one person might be the guesser and another the answerer.

So the core round would conceptually be:

**2+ players → everybody receives one hidden identity → everybody exposes their screen → players ask one Yes/No question per turn → anybody may attempt a guess according to the agreed rules → first correct identification wins the round.**

We don't necessarily need the app to enforce any of those rules.

But **we need the product specification to know what game it is supporting.**

And one final refinement: because BiGuess will extend far beyond people/characters, the natural question eventually won't always be:

> “Who am I?”

For countries, foods, animals, objects, etc., it becomes:

> **“Who or what am I?”**

That sounds like a tiny wording detail now, but these are exactly the assumptions worth fixing before they get buried throughout the UI, data model and source code.

So I would consider our first foundational decision established:

> **BiGuess is an offline-first, face-to-face social guessing platform where smartphones replace the preparation and physical mystery cards—not the human interaction. Two or more players each receive a hidden identity, expose it to everyone else, and deduce their own identity through turn-based Yes-or-No conversation.**

From here, the next blueprint section should be **Product Principles — the rules BiGuess will refuse to compromise even as it grows.**

---

