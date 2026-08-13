<script>
    import { page } from "$app/state";
    import { fade } from "svelte/transition";
    import { sineIn, sineOut } from "svelte/easing";
    import Noscript from "$lib/components/Noscript.svelte";
    import Card from "$lib/components/ui/Card.svelte";
    let { children, data } = $props();
</script>

<style>
    .settings-container {
        display: grid;
        gap: 2rem;
        grid-template-columns: 200px 1fr;
        grid-template-rows: 1fr;
    }
    .settings-menu-link {
        color: var(--fg-1);
        padding: 0.75rem 1rem;
        border-radius: var(--radius-lg, 12px);
        text-decoration: none;
        font-weight: 500;
        transition: all var(--transition-fast, 0.2s);
        display: block;
    }
    .settings-menu-link:hover {
        background: color-mix(in srgb, var(--fg-0) 5%, transparent);
        color: var(--fg-0);
    }
    .settings-menu-link.current {
        background: color-mix(in srgb, var(--main) 15%, transparent);
        color: var(--main);
        font-weight: 600;
    }
    .settings-menu-nav {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
    }
    @media only screen and (max-width: 800px) {
        .settings-container {
            grid-template-columns: 1fr;
            grid-template-rows: auto 1fr;
        }
        .settings-menu-nav {
            flex-direction: row;
            overflow-x: auto;
            white-space: nowrap;
            border-bottom: 1px solid color-mix(in srgb, var(--fg-0) 10%, transparent);
            padding-bottom: 1rem;
        }
        .settings-menu-link {
            display: inline-block;
        }
    }
</style>

<svelte:head>
  <title>Quizfreely Settings</title>
</svelte:head>

<Noscript />

<div class="grid page">
    <div class="settings-container" style="margin-top: 2rem;">
        <div>
            <h2 style="margin-top: 0; margin-bottom: 1.5rem; font-size: 1.5rem; padding-left: 1rem;">Settings</h2>
            <div class="settings-menu-nav">
                <a href="/settings" class="settings-menu-link {page.data.settingsSection == 'general' ? 'current' : ''}">General</a>
                <a href="/settings/account" class="settings-menu-link {page.data.settingsSection == 'account' ? 'current' : ''}">Account</a>
            </div>
        </div>
        <div>
            <Card style="padding: 2.5rem; min-height: 60vh;">
                {#key data.settingsTransPageKey}
                    <div in:fade={{ duration: 120, delay: 120, easing: sineIn }} out:fade={{ duration: 120, easing: sineOut }}>
                        {@render children()}
                    </div>
                {/key}
            </Card>
        </div>
    </div>
</div>
