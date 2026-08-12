<script>
    import { page } from "$app/state";
    import { fade } from "svelte/transition";
    import { sineIn, sineOut } from "svelte/easing";
    import Noscript from "$lib/components/Noscript.svelte";
    import IconBackArrow from "$lib/icons/BackArrow.svelte";
    let { children, data } = $props();
</script>
<style>
    .top-menu-link {
        margin-top: 0px;
        color: var(--fg-1);
        padding: 0.6rem 1.2rem;
        border-radius: 2rem;
        font-weight: 600;
        transition: all var(--transition-fast);
        text-decoration: none;
    }
    .top-menu-link:hover {
        background-color: var(--bg-2);
        color: var(--fg-0);
        transform: translateY(-1px);
    }
    .top-menu-link.current {
        color: var(--fg-0);
        background-color: var(--main);
        box-shadow: 0px 4px 12px var(--main-glow);
    }
    .top-menu-link.current:hover {
        transform: none;
        background-color: var(--main-hover);
    }
    .top-menu-nav {
        display: flex;
        flex-direction: row;
        gap: 0.5rem;
        align-items: center;
        margin-bottom: 1.5rem;
        padding: 0.5rem;
        background: var(--bg-1);
        border-radius: 2.5rem;
        width: fit-content;
        box-shadow: inset 0 2px 4px rgba(0,0,0,0.1);
    }
</style>

<main>
  <div class="grid page">
    <div class="content">
        <div class="top-menu-nav">
            <a class="top-menu-link {
                page?.data?.dashboardPage == "dashboard" ?
                    "current" : ""
            }" href="/dashboard">Dashboard</a>
            <a class="top-menu-link {
                page?.data?.dashboardPage == "stats" ?
                    "current" : ""
            }" href="/dashboard/stats">Progress &amp; Stats</a>
            <!-- <a class="top-menu-link { -->
            <!--     page?.data?.dashboardPage == "activities" ? -->
            <!--         "current" : "" -->
            <!-- }" href="/dashboard/activities">Activities &amp; Games</a> -->
        </div>
        {#key data.dashboardTransPageKey}
            <!-- uncomment out the style too when you uncomment the meun above -->
            <div style="margin-top: 1.4rem;" in:fade={{ duration: 120, delay: 120, easing: sineIn }} out:fade={{ duration: 120, easing: sineOut }}>
                {@render children()}
            </div>
        {/key}
    </div>
  </div>
</main>
