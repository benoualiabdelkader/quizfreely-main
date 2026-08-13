<script>
    import { page } from "$app/state";
    import { onMount } from "svelte";
    import { trackerState, CHECKLIST_STEPS } from "$lib/trackerState.svelte.js";
    import CheckmarkIcon from "$lib/icons/Checkmark.svelte";
    import WorkspaceViews from "$lib/components/wave-01/WorkspaceViews.svelte";

    let roundId = $derived(page.params.roundId);
    let round = $derived(trackerState.rounds[roundId]);
    let tense = $derived(round ? trackerState.tenses[round.tenseId] : null);
    let rProgress = $derived(trackerState.getRoundProgress(roundId));

    let activeWorkspace = $state(null);

    onMount(() => {
        trackerState.init();
    });

    function openWorkspace(stepId) {
        activeWorkspace = stepId;
        window.scrollTo({ top: 0, behavior: 'smooth' });
    }
</script>

<svelte:head>
    <title>{round ? round.name : 'Round'} | Wave 01 Tracker</title>
</svelte:head>

<div class="content" style="padding-top: 2rem;">
    {#if !trackerState.loaded || !round || !tense}
        <div class="flex center" style="height: 200px;">
            <p class="fg1">Loading round...</p>
        </div>
    {:else}
        <div style="margin-bottom: 2rem;">
            {#if activeWorkspace}
                <!-- Hidden breadcrumbs in workspace view to save space -->
            {:else}
                <a href="/wave-01/tense/{tense.id}" class="fg1" style="display: inline-block; margin-bottom: 1rem; text-decoration: none; font-weight: 500;">
                    &larr; Back to {tense.name}
                </a>
                <p class="fg1" style="margin: 0; font-size: 1rem; text-transform: uppercase; letter-spacing: 2px;">{tense.name}</p>
                <h1 class="text-gradient" style="margin-top: 0.25rem; margin-bottom: 0.5rem; font-size: 2.5rem;">{round.name || 'Untitled Round'}</h1>
                
                {#if round.description}
                    <p class="fg1" style="margin-bottom: 0.5rem; font-size: 1.1rem;">{round.description}</p>
                {/if}
                {#if round.vocabularyInfo}
                    <p class="fg1" style="margin-top: 0; font-size: 1rem; font-weight: 500; color: #03DAC6;">Vocab: {round.vocabularyInfo}</p>
                {/if}
            {/if}
        </div>
        
        {#if activeWorkspace}
            <WorkspaceViews {round} activeStage={activeWorkspace} onClose={() => activeWorkspace = null} />
        {:else}
            <div class="glass-panel" style="padding: 2.5rem; border-radius: var(--radius-xl); margin-bottom: 2rem;">
                <div class="flex justify-between" style="align-items: center; margin-bottom: 1.5rem; flex-wrap: wrap; gap: 1rem;">
                    <h2 style="margin: 0;">Round Progress</h2>
                    {#if rProgress.status === 'COMPLETED'}
                        <span style="background: rgba(3, 218, 198, 0.15); color: #03DAC6; padding: 8px 16px; border-radius: 8px; font-size: 0.85rem; font-weight: 700;">COMPLETED</span>
                    {:else if rProgress.status === 'NEEDS REVIEW'}
                        <span style="background: rgba(255, 107, 107, 0.15); color: #FF6B6B; padding: 8px 16px; border-radius: 8px; font-size: 0.85rem; font-weight: 700;">NEEDS REVIEW</span>
                    {:else if rProgress.status === 'READY FOR CHECKPOINT'}
                        <span style="background: rgba(255, 193, 7, 0.15); color: #FFC107; padding: 8px 16px; border-radius: 8px; font-size: 0.85rem; font-weight: 700;">READY FOR CHECKPOINT</span>
                    {:else if rProgress.status === 'IN PROGRESS'}
                        <span style="background: rgba(108, 99, 255, 0.15); color: var(--main); padding: 8px 16px; border-radius: 8px; font-size: 0.85rem; font-weight: 700;">IN PROGRESS</span>
                    {:else}
                        <span style="background: rgba(255, 255, 255, 0.1); color: var(--fg-1); padding: 8px 16px; border-radius: 8px; font-size: 0.85rem; font-weight: 700;">NOT STARTED</span>
                    {/if}
                </div>
                
                <p class="fg1" style="font-size: 0.95rem; margin-bottom: 1rem;">{rProgress.completed} / {rProgress.total} stages completed</p>
                <div class="flex center" style="gap: 1rem; margin-bottom: 3rem;">
                    <div style="flex-grow: 1; height: 16px; background: rgba(255,255,255,0.1); border-radius: 8px; overflow: hidden; box-shadow: inset 0 2px 4px rgba(0,0,0,0.2);">
                        <div style="height: 100%; width: {rProgress.percent}%; background: linear-gradient(90deg, var(--main), #03DAC6); transition: width 0.4s cubic-bezier(0.4, 0, 0.2, 1);"></div>
                    </div>
                    <span style="font-weight: 700; font-size: 1.5rem; width: 60px; text-align: right;">{rProgress.percent}%</span>
                </div>
                
                <h3 style="margin-bottom: 1.5rem; font-size: 1.25rem;">Mission Objectives (Learning Timeline)</h3>
                
                <div class="flex col" style="gap: 1.5rem; position: relative;">
                    <!-- Vertical connecting line -->
                    <div style="position: absolute; top: 20px; bottom: 20px; left: 34px; width: 2px; background: rgba(255,255,255,0.1); z-index: 0;"></div>
                    
                    {#each CHECKLIST_STEPS as step, i}
                        {@const isCompleted = round.checklist[step.id]?.completed}
                        <button 
                            class="glass-panel step-button" 
                            style="position: relative; z-index: 1; display: flex; align-items: center; padding: 1.5rem; border-radius: var(--radius-md); background: {isCompleted ? 'rgba(3, 218, 198, 0.05)' : 'rgba(255,255,255,0.02)'}; border: 1px solid {isCompleted ? 'rgba(3, 218, 198, 0.3)' : 'rgba(255,255,255,0.05)'}; cursor: pointer; text-align: left; transition: all 0.2s;"
                            onclick={() => openWorkspace(step.id)}
                        >
                            <div class="flex center" style="justify-content: center; min-width: 36px; height: 36px; border-radius: 50%; margin-right: 1.5rem; background: {isCompleted ? '#03DAC6' : 'rgba(0,0,0,0.8)'}; border: 2px solid {isCompleted ? '#03DAC6' : 'rgba(255,255,255,0.3)'}; transition: all 0.2s;">
                                {#if isCompleted}
                                    <CheckmarkIcon style="color: #000; width: 18px; height: 18px;" />
                                {:else}
                                    <span style="font-size: 0.9rem; font-weight: 700; color: var(--fg-1);">{i + 1}</span>
                                {/if}
                            </div>
                            <div style="flex-grow: 1;">
                                <div class="flex justify-between" style="align-items: center; margin-bottom: 0.25rem;">
                                    <span style="font-size: 1.25rem; font-weight: {isCompleted ? '600' : '500'}; color: {isCompleted ? '#03DAC6' : 'var(--fg-0)'}; transition: all 0.2s;">{step.label}</span>
                                    
                                    {#if step.id === 'checkpoint' && round.checklist.checkpoint.completed}
                                        <span style="font-size: 0.85rem; background: rgba(0,0,0,0.3); padding: 4px 8px; border-radius: 6px;">Score: {round.checklist.checkpoint.overall}%</span>
                                    {/if}
                                </div>
                                <span style="display: block; font-size: 0.95rem; color: var(--fg-1);">{step.desc}</span>
                            </div>
                        </button>
                    {/each}
                </div>
            </div>
        {/if}
    {/if}
</div>

<style>
    .step-button:hover {
        background: rgba(255,255,255,0.08) !important;
        transform: translateX(5px);
        border-color: rgba(255,255,255,0.2) !important;
    }
    .step-button:active {
        transform: translateX(2px);
    }
</style>
