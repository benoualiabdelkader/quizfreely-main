<script>
    import { page } from "$app/state";
    import { fade } from "svelte/transition";
    import { sineIn, sineOut } from "svelte/easing";
    import Noscript from "$lib/components/Noscript.svelte";
    import IconBackArrow from "$lib/icons/BackArrow.svelte";
    let { children, data } = $props();
</script>

<style>
    .tabs-container {
        display: flex;
        flex-direction: row;
        gap: 0.5rem;
        align-items: center;
        margin-bottom: 2rem;
        border-bottom: 1px solid color-mix(in srgb, var(--fg-0) 10%, transparent);
        padding-bottom: 0.5rem;
        overflow-x: auto;
        white-space: nowrap;
    }
    
    .tab-link {
        color: var(--fg-1);
        padding: 0.5rem 1rem;
        border-radius: var(--radius-lg, 12px);
        text-decoration: none;
        font-weight: 500;
        transition: all var(--transition-fast, 0.2s);
    }
    
    .tab-link:hover {
        background: color-mix(in srgb, var(--fg-0) 5%, transparent);
        color: var(--fg-0);
    }
    
    .tab-link.current {
        background: color-mix(in srgb, var(--main) 15%, transparent);
        color: var(--main);
        font-weight: 600;
    }
</style>

<main>
  <div class="grid page">
    <div class="content" style="background: var(--bg-1); border-radius: var(--radius-xl); padding: 2rem; box-shadow: 0 10px 30px rgba(0,0,0,0.1);">
        <div class="tabs-container">
            <a class="tab-link {page?.data?.explorePage == 'subjects' ? 'current' : ''}" href="/explore">Subjects</a>
            <a class="tab-link {page?.data?.explorePage == 'recently-created' ? 'current' : ''}" href="/explore/recent">Recently Created</a>
            <a class="tab-link {page?.data?.explorePage == 'recently-updated' ? 'current' : ''}" href="/explore/recent?updated">Recently Updated</a>
        </div>
        {#key data.exploreTransPageKey}
            <div in:fade={{ duration: 120, delay: 120, easing: sineIn }} out:fade={{ duration: 120, easing: sineOut }}>
                {@render children()}
            </div>
        {/key}
    </div>
  </div>
</main>
