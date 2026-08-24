//
//  AVCoordinator.swift
//  Stingray
//
//  Created by Ben Roberts on 7/4/26.
//

import AVKit
import UIKit

public class AVPlayerCoordinator: NSObject, AVPlayerViewControllerDelegate {
    public let onStartPiP: () -> Void
    public let onRestoreFromPiP: () -> Void
    public let onStopFromPiP: () -> Void
    /// Used for PiP identification
    public let id: String

    // Maintain a reference to a PiP instance
    public weak var playerViewController: AVPlayerViewController?
    // Maintain a reference to this Coordinator while PiP is active
    public static var activePiPCoordinator: AVPlayerCoordinator?

    // Track whether we're restoring vs closing
    private var isRestoringFromPiP = false

    // Keep error observation alive for the lifetime of the coordinator
    private var currentItemObservation: NSKeyValueObservation?
    private var itemStatusObservation: NSKeyValueObservation?
    private var failedToPlayObserver: NSObjectProtocol?

    public init(
        id: String,
        onStartPiP: @escaping () -> Void,
        onRestoreFromPiP: @escaping () -> Void,
        onStopFromPiP: @escaping () -> Void,
    ) {
        self.id = id
        self.onStartPiP = onStartPiP
        self.onRestoreFromPiP = onRestoreFromPiP
        self.onStopFromPiP = onStopFromPiP
    }

    public func stopPlayer() {
        // On tvOS, stopping the player will end PiP automatically
        playerViewController?.player?.pause()
        playerViewController?.player?.replaceCurrentItem(with: nil)
    }

    // AI Generated
    /// Logs playback failures for `player`, re-hooking observation whenever its current item changes.
    /// - Parameter player: The player whose current item should be watched for failures.
    public func observeFailures(of player: AVPlayer) {
        self.currentItemObservation = player.observe(\.currentItem, options: [.initial, .new]) { [weak self] player, _ in
            self?.observeFailures(of: player.currentItem)
        }
    }

    // AI Generated
    private func observeFailures(of item: AVPlayerItem?) {
        if let failedToPlayObserver { NotificationCenter.default.removeObserver(failedToPlayObserver) }
        self.itemStatusObservation = nil
        self.failedToPlayObserver = nil
        guard let item else { return }

        self.itemStatusObservation = item.observe(\.status, options: [.new]) { item, _ in
            if item.status == .failed {
                Log.error("Player item failed to load: \(item.error?.localizedDescription ?? "Unknown error")")
            }
        }

        self.failedToPlayObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.failedToPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { notification in
            let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            Log.error("Playback failed to reach end: \(error?.localizedDescription ?? "Unknown error")")
        }
    }

    // AI Generated
    deinit {
        if let failedToPlayObserver { NotificationCenter.default.removeObserver(failedToPlayObserver) }
    }

    public func playerViewControllerWillStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
        Log.info("PiP starting")
        self.onStartPiP()
        Self.activePiPCoordinator = self // Keep self alive
    }

    public func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
        Log.info("PiP stopped")
        if !isRestoringFromPiP {
            onStopFromPiP()
        }

        isRestoringFromPiP = false // Reset for next time
        Self.activePiPCoordinator = nil
    }

    public func playerViewController(
        _ playerViewController: AVPlayerViewController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        Log.warning("PiP failed to start: \(error)")
        Self.activePiPCoordinator = nil
    }

    public func playerViewControllerShouldAutomaticallyDismissAtPictureInPictureStart(
        _ playerViewController: AVPlayerViewController
    ) -> Bool {
        true
    }

    public func playerViewController(
        _ playerViewController: AVPlayerViewController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        Log.info("Restoring UI from PiP")
        isRestoringFromPiP = true // Flag that this is a restore, not a close
        onRestoreFromPiP()
        completionHandler(true)
    }
}
