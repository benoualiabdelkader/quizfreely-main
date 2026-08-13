<script>
    import { idbApiLayer } from "$lib/idb-api-layer";
    import CheckmarkIcon from "$lib/icons/Checkmark.svelte";
    import XMarkIcon from "$lib/icons/CloseXMark.svelte";
    import { onMount } from "svelte";

    let { term, answerWith, viewOnly, showAccuracy, answerUpdateCallback, showCorrectAnswer, answeredString: initAnsweredString, userMarkedCorrectChangeCallback, questionId: initQuestionId } = $props();
    let manuallyMarkedCorrect = $state(false);

    let questionId = initQuestionId;
    export function setQuestionId(id) {
        questionId = id;
    }
    
    // Derived answer from pills
    let answer = $derived(selectedPills.map(p => p.word).join(" ").trim());
    
    export function getQuestion() {
        if (answer == "") {
            console.log("Possibly Unanswered Unscramble")
        }
        return {
            id: questionId,
            frq: { // Piggyback on FRQ schema
                term: {
                    id: term.id,
                    term: term.term,
                    def: term.def
                },
                answerWith: answerWith,
                correct: manuallyMarkedCorrect || (answerWith == "DEF" ?
                    term.def.trim().toLowerCase() == answer.toLowerCase() :
                    term.term.trim().toLowerCase() == answer.toLowerCase()
                ),
                userMarkedCorrect: manuallyMarkedCorrect,
                answeredString: answer,
            }
        }
    }
    
    export function isAnswered() {
        return selectedPills.length > 0;
    }

    let allPills = $state([]);
    let selectedPills = $state([]);
    let availablePills = $state([]);

    onMount(() => {
        const rawTermText = answerWith == "DEF" ? term.term : term.def;
        const cleanedText = rawTermText.replace("[UNSCRAMBLE]\n", "");
        
        let words = [];
        if (cleanedText.includes("/")) {
            words = cleanedText.split("/").map(s => s.trim()).filter(s => s.length > 0);
        } else {
            words = cleanedText.split(" ").map(s => s.trim()).filter(s => s.length > 0);
        }
        
        allPills = words.map((w, i) => ({ id: i, word: w }));
        
        if (initAnsweredString) {
            // Reconstruct state from previous answer if possible
            let currentAvailable = [...allPills];
            let newSelected = [];
            
            const answeredWords = initAnsweredString.split(" ");
            for (const aw of answeredWords) {
                const foundIdx = currentAvailable.findIndex(p => p.word === aw);
                if (foundIdx !== -1) {
                    newSelected.push(currentAvailable[foundIdx]);
                    currentAvailable.splice(foundIdx, 1);
                }
            }
            selectedPills = newSelected;
            availablePills = currentAvailable;
        } else {
            selectedPills = [];
            availablePills = [...allPills];
        }
    });

    async function updateQForManualMarkedCorrect() {
        if (questionId == null) {
            console.error("updateQForManualMarkedCorrect: questionId is null")
            return false;
        }
        const intendedManuallyMarkedCorrect = !manuallyMarkedCorrect;
        const intendedCorrect = intendedManuallyMarkedCorrect || (answerWith == "DEF" ?
            term.def.trim().toLowerCase() == answer.toLowerCase() :
            term.term.trim().toLowerCase() == answer.toLowerCase()
        );
        // UUIDs have dashes/hyphens. cloud uses UUIDs, local uses sequential ids.
        if ((""+questionId).includes("-")) {
            try {
                const raw = await fetch("/api/graphql", {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json"
                    },
                    body: JSON.stringify({
                        query: `mutation userMarkedCorrectChangeFRQ($id: ID!, $c: Boolean!, $umc: Boolean) {
                            updatePracticeTestQuestion(id: $id, correct: $c, userMarkedCorrect: $umc): { id }
                        }`,
                        variables: {
                            id: questionId,
                            c: intendedCorrect,
                            umc: intendedManuallyMarkedCorrect
                        }
                    })
                });
                const resp = await raw.json();
                return resp?.data?.updatePracticeTestQuestion?.id != null
            } catch (err) {
                console.error("Error in userMarkedCorrectChangeFRQ gql req:", err)
                return false;
            }
        } else {
            try {
                const res = await idbApiLayer.updatePracticeTestQuestion(questionId, intendedCorrect, intendedManuallyMarkedCorrect);
                return res?.id != null;
            } catch (err) {
                console.error("Error from FRQ idbApiLayer updatePracticeTestQuesetion:", err);
                return false;
            }
        }
    }
    
    function tapAvailable(pill, index) {
        if (viewOnly) return;
        availablePills.splice(index, 1);
        selectedPills.push(pill);
        answerUpdateCallback?.();
    }
    
    function tapSelected(pill, index) {
        if (viewOnly) return;
        selectedPills.splice(index, 1);
        availablePills.push(pill);
        answerUpdateCallback?.();
    }
</script>

<style>
    .pill-area {
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
        min-height: 3rem;
        padding: 1rem;
        border: 2px dashed var(--bg2);
        border-radius: 0.5rem;
        margin-bottom: 1rem;
        align-items: center;
        transition: 0.2s;
    }
    
    .pill-area.active {
        border: 2px solid var(--main);
        background-color: var(--bg1);
    }
    
    .pill {
        padding: 0.5rem 1rem;
        background-color: var(--bg2);
        border: 1px solid var(--bg3);
        border-radius: 2rem;
        cursor: pointer;
        user-select: none;
        transition: 0.15s;
        font-size: 1.1rem;
    }
    
    .pill:hover {
        background-color: var(--bg3);
        transform: translateY(-2px);
    }
    
    .pill.selected {
        background-color: var(--main);
        color: var(--bg0);
        border-color: var(--main);
    }
    
    .pill.selected:hover {
        background-color: var(--main-hover);
    }
</style>

<div>
    <p class="fg0">Tap words to build the correct { answerWith == "DEF" ? "definition" : "term"}</p>
    
    <!-- The constructed answer area -->
    <div class="pill-area {selectedPills.length > 0 ? 'active' : ''} {showAccuracy ? (getQuestion().frq.correct ? 'yay' : 'ohno') : ''}">
        {#if selectedPills.length === 0}
            <span class="fg0" style="opacity: 0.5; font-style: italic;">Tap words below to form your answer...</span>
        {/if}
        {#each selectedPills as pill, index (pill.id)}
            <!-- svelte-ignore a11y_click_events_have_key_events -->
            <!-- svelte-ignore a11y_no_static_element_interactions -->
            <div class="pill selected" onclick={() => tapSelected(pill, index)}>
                {pill.word}
            </div>
        {/each}
        
        {#if showAccuracy && getQuestion().frq.correct}
            <span class="yay" style="margin-left: auto;"><CheckmarkIcon width="1.6rem" height="1.6rem"></CheckmarkIcon></span>
        {:else if showAccuracy}
            <span class="ohno" style="margin-left: auto;"><XMarkIcon width="1.6rem" height="1.6rem"></XMarkIcon></span>
        {/if}
    </div>
    
    <!-- The available scrambled words -->
    <div class="flex" style="flex-wrap: wrap; gap: 0.5rem; margin-bottom: 1.5rem;">
        {#each availablePills as pill, index (pill.id)}
            <!-- svelte-ignore a11y_click_events_have_key_events -->
            <!-- svelte-ignore a11y_no_static_element_interactions -->
            <div class="pill" onclick={() => tapAvailable(pill, index)}>
                {pill.word}
            </div>
        {/each}
    </div>

    {#if showAccuracy && showCorrectAnswer}
        <p class="fg0">Correct { answerWith == "DEF" ? "definition" : "term"}:</p>
        <p class={(answerWith == "DEF" ? term.def : term.term)?.length < 20 ? "h4" : ""} style="white-space: pre-wrap; margin-bottom: 0px; margin-top: 0.2rem;">{ answerWith == "DEF" ?
            term.def : term.term
        }</p>
    {/if}
    
    {#if showAccuracy && manuallyMarkedCorrect}
        <div class="flex" style="align-items: center; margin-top: 1rem;">
            <p class="fg0">Manually marked correct</p>
            <button class="warn alt" onclick={async () => {
                if (await updateQForManualMarkedCorrect() === false) {
                    console.error("error undoing manual correct marking on FRQ");
                    alert("oops, it kind of didn't work. check your internet and everything");
                } else {
                    manuallyMarkedCorrect = false;
                    userMarkedCorrectChangeCallback?.();
                }
            }}>Undo?</button>
        </div>
    {:else if showAccuracy && showCorrectAnswer && !getQuestion().frq.correct}
        <button class="warn alt" style="margin-top: 1rem;" onclick={async () => {
            if (await updateQForManualMarkedCorrect() === false) {
                console.error("error manually marking FRQ correct");
                alert("oops, it kind of didn't work. check your internet and everything");
            } else {
                manuallyMarkedCorrect = true;
                userMarkedCorrectChangeCallback?.();
            }
        }}>Manually mark as correct?</button>
    {/if}
    
    {#if showAccuracy && showCorrectAnswer}
        <div style="margin-top: 1rem;">
        <button class="faint" onclick={() => {
            showCorrectAnswer = false;
        }}>Hide Correct Answer</button>
        </div>
    {:else if showAccuracy && (manuallyMarkedCorrect || !getQuestion().frq.correct)}
        <div style="margin-top: 1rem;">
        <button class="faint" onclick={() => {
            showCorrectAnswer = true;
        }}>Show Correct Answer</button>
        </div>
    {/if}
</div>
