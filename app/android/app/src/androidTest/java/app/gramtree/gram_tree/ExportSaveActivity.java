package app.gramtree.gram_tree;

import android.app.Activity;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.provider.OpenableColumns;
import java.io.InputStream;
import java.io.OutputStream;

/** Test-only receiving app, using only framework APIs in its separate process. */
public class ExportSaveActivity extends Activity {
    private Uri stream;

    @Override
    public void onCreate(Bundle state) {
        super.onCreate(state);
        stream = state == null ? getIntent().getParcelableExtra(Intent.EXTRA_STREAM)
                : state.getParcelable("stream");
        if (state != null) return;
        try {
            if (stream == null) throw new IllegalStateException("Missing stream");
            String name;
            try (Cursor cursor = getContentResolver().query(stream,
                    new String[]{OpenableColumns.DISPLAY_NAME}, null, null, null)) {
                if (cursor == null || !cursor.moveToFirst()) throw new IllegalStateException("Missing name");
                name = cursor.getString(0);
            }
            // The receiving app must really have read access before opening DocumentsUI.
            try (InputStream input = getContentResolver().openInputStream(stream)) {
                if (input == null || input.read() != 0x50) throw new IllegalStateException("Unreadable ZIP");
            }
            Intent create = new Intent(Intent.ACTION_CREATE_DOCUMENT)
                    .addCategory(Intent.CATEGORY_OPENABLE)
                    .setType("application/zip")
                    .putExtra(Intent.EXTRA_TITLE, name);
            startActivityForResult(create, 1);
        } catch (Exception error) {
            report(null);
        }
    }

    @Override
    public void onSaveInstanceState(Bundle state) {
        state.putParcelable("stream", stream);
        super.onSaveInstanceState(state);
    }

    @Override
    public void onActivityResult(int request, int result, Intent data) {
        super.onActivityResult(request, result, data);
        if (request != 1) return;
        try {
            if (result != RESULT_OK || data == null || data.getData() == null) {
                throw new IllegalStateException("Save did not complete");
            }
            Uri destination = data.getData();
            try (InputStream input = getContentResolver().openInputStream(stream);
                 OutputStream output = getContentResolver().openOutputStream(destination, "w")) {
                if (input == null || output == null) throw new IllegalStateException("Missing stream");
                byte[] buffer = new byte[8192];
                int count;
                while ((count = input.read(buffer)) != -1) output.write(buffer, 0, count);
            }
            report(destination);
        } catch (Exception error) {
            report(null);
        }
    }

    private void report(Uri destination) {
        int grants = Intent.FLAG_GRANT_READ_URI_PERMISSION | Intent.FLAG_GRANT_WRITE_URI_PERMISSION;
        if (stream != null) {
            // Keep source verification access after this receiver Activity finishes.
            grantUriPermission("app.gramtree.gram_tree", stream, grants);
        }
        if (destination != null) {
            // Keep saved-document verification access after this receiver Activity finishes.
            grantUriPermission("app.gramtree.gram_tree", destination, grants);
        }
        sendBroadcast(completionIntent(stream, destination));
        finish();
    }

    static Intent completionIntent(Uri source, Uri destination) {
        // An action-only receiver rejects broadcasts with a non-null data URI.
        return new Intent("app.gramtree.TEST_ZIP_SAVED")
                .setPackage("app.gramtree.gram_tree")
                .putExtra("source", source).putExtra("destination", destination);
    }
}
