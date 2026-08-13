<script>
    import { page } from "$app/state";
    import { onMount } from "svelte";
    import { trackerState } from "$lib/trackerState.svelte.js";
    import IconPlus from "$lib/icons/Plus.svelte";
    import Card from "$lib/components/ui/Card.svelte";
    import Button from "$lib/components/ui/Button.svelte";
    import Modal from "$lib/components/ui/Modal.svelte";
    import Input from "$lib/components/ui/Input.svelte";

    let tenseId = $derived(page.params.tenseId);
    let tense = $derived(trackerState.tenses[tenseId]);
    let progress = $derived(trackerState.getTenseProgress(tenseId));

    let showModal = $state(false);
    let newRoundName = $state("");
    let newRoundDesc = $state("");
    let newRoundVocab = $state("");

    onMount(() => {
        trackerState.init();
    });

    function handleCreateRound() {
        if (!newRoundName.trim()) return;
        trackerState.createRound(tenseId, newRoundName, newRoundDesc, newRoundVocab);
        showModal = false;
        newRoundName = "";
        newRoundDesc = "";
        newRoundVocab = "";
    }
</script>

<svelte:head>
    <title>{tense ? tense.name : 'Tense'} | Wave 01 Tracker</title>
</svelte:head>

<div class="content" style="padding-top: 2rem;">
    {#if !trackerState.loaded || !tense}
        <div class="flex center" style="height: 200px;">
            <p class="fg1">Loading tense...</p>
        </div>
    {:else}
        <a href="/wave-01" class="fg1" style="display: inline-block; margin-bottom: 1rem; text-decoration: none; font-weight: 500;">&larr; Back to Tracker</a>
        
        <Card style="padding: 2.5rem; margin-bottom: 2.5rem;">
            <h1 class="text-gradient" style="margin-top: 0; margin-bottom: 0.5rem; font-size: 2.5rem;">{tense.name}</h1>
            <p class="fg1" style="font-size: 1.1rem; margin-bottom: 2rem; max-width: 600px;">{tense.description}</p>
            
            <div class="flex" style="gap: 3rem; margin-bottom: 2.5rem; flex-wrap: wrap;">
                <div>
                    <p class="fg1" style="margin: 0 0 0.5rem 0; font-size: 0.9rem;">Overall Progress</p>
                    <div class="flex center" style="gap: 1rem; min-width: 200px;">
                        <div style="flex-grow: 1; height: 12px; background: var(--bg-2); border-radius: 6px; overflow: hidden;">
                            <div style="height: 100%; width: {progress.percent}%; background: linear-gradient(90deg, var(--main), #03DAC6); transition: width 0.4s ease;"></div>
                        </div>
                        <span style="font-weight: 700; font-size: 1.2rem;">{progress.percent}%</span>
                    </div>
                </div>
                
                <div>
                    <p class="fg1" style="margin: 0 0 0.5rem 0; font-size: 0.9rem;">Total Rounds</p>
                    <p style="margin: 0; font-size: 1.2rem; font-weight: 600;">{progress.totalRounds}</p>
                </div>
                
                <div>
                    <p class="fg1" style="margin: 0 0 0.5rem 0; font-size: 0.9rem;">Completed</p>
                    <p style="margin: 0; font-size: 1.2rem; font-weight: 600; color: #03DAC6;">{progress.completedRounds}</p>
                </div>
                
                <div>
                    <p class="fg1" style="margin: 0 0 0.5rem 0; font-size: 0.9rem;">Active</p>
                    <p style="margin: 0; font-size: 1.2rem; font-weight: 600; color: var(--main);">{progress.totalRounds - progress.completedRounds}</p>
                </div>
            </div>
            
            <Button variant="primary" style="height: 3rem; padding: 0 2rem; font-size: 1.05rem;" onclick={() => showModal = true}>
                <IconPlus /> Create New Round
            </Button>
        </Card>

        <h2 style="margin-bottom: 1.5rem; font-size: 1.75rem;">Rounds</h2>
        
        {#if tense.roundIds.length === 0}
            <Card style="padding: 3rem; text-align: center;">
                <p class="fg1" style="font-size: 1.1rem; margin-bottom: 1.5rem;">You haven't created any rounds for this tense yet.</p>
                <Button variant="primary" onclick={() => showModal = true}><IconPlus /> Create Your First Round</Button>
            </Card>
        {:else}
            <div class="grid" style="grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 1.5rem;">
                {#each tense.roundIds as roundId, i}
                    {@const round = trackerState.rounds[roundId]}
                    {@const rProgress = trackerState.getRoundProgress(roundId)}
                    
                    <a href="/wave-01/round/{roundId}" style="text-decoration: none; color: inherit; display: block;">
                        <Card interactive={true} style="display: flex; flex-direction: column; padding: 1.5rem; height: 100%;">
                            <div class="flex justify-between" style="margin-bottom: 0.5rem; align-items: flex-start;">
                                <h3 style="margin: 0; font-size: 1.25rem;">{round.name || `Round ${i + 1}`}</h3>
                                {#if rProgress.status === 'COMPLETED'}
                                    <span style="background: color-mix(in srgb, #03DAC6 15%, transparent); color: #03DAC6; padding: 4px 8px; border-radius: 6px; font-size: 0.75rem; font-weight: 600;">COMPLETED</span>
                                {:else if rProgress.status === 'IN PROGRESS'}
                                    <span style="background: color-mix(in srgb, var(--main) 15%, transparent); color: var(--main); padding: 4px 8px; border-radius: 6px; font-size: 0.75rem; font-weight: 600;">IN PROGRESS</span>
                                {:else}
                                    <span style="background: var(--bg-2); color: var(--fg-1); padding: 4px 8px; border-radius: 6px; font-size: 0.75rem; font-weight: 600;">NOT STARTED</span>
                                {/if}
                            </div>
                            
                            {#if round.vocabularyInfo}
                                <p class="fg1" style="font-size: 0.9rem; margin-top: 0; margin-bottom: 1rem;"><strong>Vocab:</strong> {round.vocabularyInfo}</p>
                            {/if}
                            
                            {#if round.description}
                                <p class="fg1" style="font-size: 0.95rem; margin-bottom: 1.5rem; flex-grow: 1;">{round.description}</p>
                            {:else}
                                <div style="flex-grow: 1;"></div>
                            {/if}
                            
                            <div class="flex center" style="gap: 0.75rem; margin-top: 1.5rem;">
                                <div style="flex-grow: 1; height: 8px; background: var(--bg-2); border-radius: 4px; overflow: hidden;">
                                    <div style="height: 100%; width: {rProgress.percent}%; background: {rProgress.percent === 100 ? '#03DAC6' : 'var(--main)'}; transition: width 0.3s ease;"></div>
                                </div>
                                <span style="font-weight: 600; font-size: 0.95rem;">{rProgress.percent}%</span>
                            </div>
                        </Card>
                    </a>
                {/each}
            </div>
        {/if}
    {/if}
</div>

<Modal bind:show={showModal} title="Create Round">
    <p class="fg1" style="margin-bottom: 1.5rem; font-size: 0.95rem; line-height: 1.5;">
        Tense: <strong class="fg0">{tense?.name}</strong><br>
        <span style="font-size: 0.85rem; opacity: 0.8;">You can create unlimited rounds inside the same tense. Every round has its own independent 10-step checklist.</span>
    </p>
    
    <div style="margin-bottom: 1.25rem;">
        <label for="roundName" class="fg1" style="display: block; margin-bottom: 0.5rem; font-size: 0.9rem; font-weight: 500;">Round name</label>
        <Input id="roundName" bind:value={newRoundName} placeholder="e.g. Past Simple — Verbs 1–10" style="width: 100%;" />
    </div>
    
    <div style="margin-bottom: 1.25rem;">
        <label for="roundDesc" class="fg1" style="display: block; margin-bottom: 0.5rem; font-size: 0.9rem; font-weight: 500;">Description (Optional)</label>
        <Input id="roundDesc" bind:value={newRoundDesc} placeholder="e.g. First 10 irregular verbs." style="width: 100%;" />
    </div>
    
    <div style="margin-bottom: 2.5rem;">
        <label for="roundVocab" class="fg1" style="display: block; margin-bottom: 0.5rem; font-size: 0.9rem; font-weight: 500;">Vocabulary / number of verbs (Optional)</label>
        <Input id="roundVocab" bind:value={newRoundVocab} placeholder="e.g. 10 verbs" style="width: 100%;" />
    </div>
    
    <div class="flex justify-between compact-gap">
        <Button variant="secondary" style="flex: 1; justify-content: center; height: 3rem;" onclick={() => showModal = false}>Cancel</Button>
        <Button variant="primary" style="flex: 1; justify-content: center; height: 3rem;" onclick={handleCreateRound} disabled={!newRoundName.trim()}>Create Round</Button>
    </div>
</Modal>
