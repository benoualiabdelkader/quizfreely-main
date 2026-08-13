<script>
    import { onMount } from "svelte";
    import { trackerState } from "$lib/trackerState.svelte.js";

    onMount(() => {
        trackerState.init();
    });
</script>

<svelte:head>
    <title>Wave 01 Tracker | Quizfreely</title>
</svelte:head>

<div class="content" style="padding-top: 2rem;">
    <h1 class="text-gradient" style="margin-bottom: 0.5rem; font-size: 2.5rem;">Wave 01 Tracker</h1>
    <p class="fg1" style="margin-bottom: 2.5rem; font-size: 1.1rem; max-width: 600px;">Track your progress through the core English tenses. Master each tense by completing independent training rounds.</p>

    {#if trackerState.loaded}
        <div class="grid" style="grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 1.5rem;">
            {#each Object.values(trackerState.tenses) as tense}
                {@const progress = trackerState.getTenseProgress(tense.id)}
                <div class="glass-panel" style="padding: 1.5rem; display: flex; flex-direction: column; height: 100%; border-radius: var(--radius-xl);">
                    <h3 style="margin-top: 0; margin-bottom: 0.5rem; font-size: 1.35rem;">{tense.name}</h3>
                    <p class="fg1" style="font-size: 0.95rem; margin-bottom: 1.5rem; flex-grow: 1;">{tense.description}</p>
                    
                    <div style="margin-bottom: 1.5rem;">
                        <div class="flex" style="justify-content: space-between; font-size: 0.9rem; margin-bottom: 0.4rem;">
                            <span class="fg1">{progress.totalRounds} Rounds</span>
                            <span class="fg1">{progress.completedRounds} Completed</span>
                        </div>
                        
                        <div class="flex center" style="gap: 0.75rem;">
                            <div style="flex-grow: 1; height: 10px; background: rgba(255,255,255,0.1); border-radius: 5px; overflow: hidden;">
                                <div style="height: 100%; width: {progress.percent}%; background: linear-gradient(90deg, var(--main), #03DAC6); transition: width 0.4s ease;"></div>
                            </div>
                            <span style="font-weight: 600; font-size: 1rem;">{progress.percent}%</span>
                        </div>
                    </div>
                    
                    <div class="flex center compact-gap">
                        <a href="/wave-01/tense/{tense.id}" class="button main" style="flex: 1; justify-content: center; height: 3rem;">Open Tense</a>
                    </div>
                </div>
            {/each}
        </div>
    {:else}
        <div class="flex center" style="height: 200px;">
            <p class="fg1">Loading tracker data...</p>
        </div>
    {/if}
</div>
