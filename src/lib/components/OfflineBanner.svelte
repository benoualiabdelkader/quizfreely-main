<script>
    import { onMount } from "svelte";
    import { processSyncQueue } from "$lib/syncEngine.js";

    let isOnline = $state(true);
    let showBanner = $state(false);

    onMount(() => {
        isOnline = navigator.onLine;
        
        if (!isOnline) {
            showBanner = true;
        }

        const handleOffline = () => {
            isOnline = false;
            showBanner = true;
        };

        const handleOnline = () => {
            isOnline = true;
            showBanner = true;
            processSyncQueue();
            
            // Hide the "online" success banner after 3 seconds
            setTimeout(() => {
                if (isOnline) showBanner = false;
            }, 3000);
        };

        window.addEventListener("offline", handleOffline);
        window.addEventListener("online", handleOnline);

        // Process queue on initial load if online
        if (isOnline) {
            processSyncQueue();
        }

        return () => {
            window.removeEventListener("offline", handleOffline);
            window.removeEventListener("online", handleOnline);
        };
    });
</script>

{#if showBanner}
    <div class="offline-banner {isOnline ? 'online' : 'offline'}">
        <div class="banner-content">
            {#if isOnline}
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
                    <polyline points="22 4 12 14.01 9 11.01"></polyline>
                </svg>
                <span><b>Online</b> - Changes synchronized successfully.</span>
            {:else}
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="1" y1="1" x2="23" y2="23"></line>
                    <path d="M16.72 11.06A10.94 10.94 0 0 1 19 12.55"></path>
                    <path d="M5 12.55a10.94 10.94 0 0 1 5.17-2.39"></path>
                    <path d="M10.71 5.05A16 16 0 0 1 22.58 9"></path>
                    <path d="M1.42 9a15.91 15.91 0 0 1 4.7-2.88"></path>
                    <path d="M8.53 16.11a6 6 0 0 1 6.95 0"></path>
                    <line x1="12" y1="20" x2="12.01" y2="20"></line>
                </svg>
                <span><b>Offline Mode</b> - All downloaded practice materials are available.</span>
            {/if}
        </div>
    </div>
{/if}

<style>
    .offline-banner {
        position: fixed;
        bottom: 24px;
        left: 50%;
        transform: translateX(-50%);
        z-index: 9999;
        padding: 12px 24px;
        border-radius: var(--radius-full, 9999px);
        font-size: 0.9rem;
        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.2);
        animation: slideUp 0.3s ease-out;
        transition: all 0.3s ease;
    }

    .banner-content {
        display: flex;
        align-items: center;
        gap: 12px;
    }

    .offline {
        background: color-mix(in srgb, var(--warning, #FF9800) 20%, var(--bg-1, #1a1a1a));
        border: 1px solid color-mix(in srgb, var(--warning, #FF9800) 40%, transparent);
        color: var(--warning, #FFB74D);
    }

    .online {
        background: color-mix(in srgb, var(--success, #4CAF50) 20%, var(--bg-1, #1a1a1a));
        border: 1px solid color-mix(in srgb, var(--success, #4CAF50) 40%, transparent);
        color: var(--success, #81C784);
    }

    @keyframes slideUp {
        from {
            transform: translate(-50%, 100%);
            opacity: 0;
        }
        to {
            transform: translate(-50%, 0);
            opacity: 1;
        }
    }
</style>
